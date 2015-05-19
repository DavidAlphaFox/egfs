# 函数规格(Client API) #

总体设计原则是和erlang的[file模块](http://www.erlang.org/doc/man/file.html)接口保持兼容，基本上可以认为是其子集。

## create ##

```
create(FileName) -> {ok, FileHandle} | {error, Reason}
```

  * 注意：用create打开的文件是独占的，也就是说不允许多个Client一起写。如果希望支持多个Client写，那么应该调用`open(FileName, [append])`。

## open ##

```
open(FileName, [Mode]) -> {ok, FileHandle} | {error, Reason}, 其中：Mode = read | append
```

## close ##

```
close(FileHandle) -> ok
```

## append ##

```
append(FileHandle, [Record]) -> {ok, [Offset]} | {error, Reason}
```

  * append的数据是record，它有边界。记录并不能够跨chunk保存，因此最大的记录为`ChunkSize`大小。如果当前chunk大小不足时，会将多余的字节以Padding填充，然后从下一个chunk继续写record。

## sync ##

```
sync(FileHandle) -> ok | {error, Reason}
```

  * 在一般文件系统中，sync的语义是确保数据写入磁盘中（即write commit）。但是对于 DFS，个人认为其实更重要的含义可以是 Writer 通知 Reader 存在新的数据可以进行读取的过程。当然，也可以引入一个 DFS 专用的 API 来做这件事情。
  * 注意：在多个客户同时写的时候，sync语义如何，需要确认。

## read ##

```
read(FileHandle, Size) -> {ok, Data} | eof | {error, Reason}
```

## position ##

```
position(FileHandle, Offset) -> {ok, Offset} | {error, Reason}
```

  * 注意：对于写模式打开的文件，调用position函数必然失败（因为我们只支持append数据，不能移动写指针）。

## pread ##

```
pread(FileHandle, Offset, Size) -> {ok, Data} | {error, Reason}
```

  * 注意：调用pread后，文件当前位置指针是未定义的。

## delete ##

```
delete(FileName) -> ok | {error, Reason}
```

  * 注意：如果当前有人打开文件，那么delete会怎么样应该明确定义。

## rename ##

```
rename(FileName, NewFileName) -> ok | {error, Reason}
```

  * 注意点同上。