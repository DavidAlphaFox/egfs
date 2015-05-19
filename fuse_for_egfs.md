# Introduction #

> <p>
我们的分布式存储系统－－egfs已经初步可用，但是如何方便地应用它，同时对它进行实际测试?<br />我们采用的方案是：<br>
<ul><li>用fuse把egfs挂载到本地;<br>
</li><li>然后在上面架上我们的corsair系统;<br>
</li><li>借助于corsair的大量用户进行测试，同时推广egfs的应用。<br /></li></ul></li></ul>

而<a href='http://code.google.com/p/fuserl/'>fuserl</a>已经实现了fuse的erlang driver, 我们就在fuserl的基础上，编写fuse相应的erlang回调函数，<br />就可以实现将egfs挂载到本地. 本文档主要描述如何用egfs提供的接口实现这些回调函数。<br>
<blockquote></p></blockquote>


<h1>Implementation Details</h1>
<p>
模块fusefs实现了所需的回调函数，回调函数统一在efs.erl文件中定义；在efs中，有一个重要的全局变量*State#egfsrv<b>,它有三个成员：<br>
<ul><li>a. inode: type＝gb_trees, 动态存储(inode, Path)值对；<br>
</li><li>b. names: type = gb_trees, 动态存储(Path, inode)值对, 与inodes的内容一一对应；<br>
</li><li>c. pids: type = ets, 动态存储(FileHandle, WorkerPid)值对。</b><br />
下面对efs中实现的回调函数的原型、所要完成的功能、返回值及实现细节进行说明。<br>
</p>

> #### getattr/4, 根据文件的inode获得文件的attributes ####
<p>
</li></ul><blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   getattr (Ctx::#fuse_ctx{}, Inode::integer (), Cont::continuation (), State) -&gt;<br>
         { getattr_async_reply (), NewState } | { noreply, NewState } <br>
   getattr_async_reply () = #fuse_reply_attr{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Get the file attributes associated with an inode.  If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont<br>
as first argument and the second argument of type getattr_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>只使用到了Inode和State两个参数；<br />
根据Inode, 查询State#inodes, 得到Path;<br />
根据Path, 调用egfs:read_file_info得到文件的相应属性，并转换为fuse所需的格式；<br />
正常返回值是{ #fuse_reply_attr{}, NewState};<br />
异常返回值是{ #fuse_reply_err{], State}.<br />
</blockquote></li></ul><blockquote></div>
</p>

> #### setattr/7, 设置与inode对应的文件的属性 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   setattr (Ctx::#fuse_ctx{}, Inode::integer (), Attr::#stat{}, ToSet::integer (),<br>
            Fi::maybe_fuse_file_info (), Cont::continuation (), State) -&gt;<br>
        { setattr_async_reply (), NewState } | { noreply, NewState }<br>
   maybe_fuse_file_info () = #fuse_file_info{} | null<br>
   setattr_async_reply () = #fuse_reply_attr{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Set file attributes.ToSet is a bitmask which defines which<br>
elements of Attr are defined and should be modified.  Possible values<br>
are defined as ?FUSE_SET_ATTR_XXXX in fuserl.hrl . Fi will be set<br>
if setattr is invoked from ftruncate under Linux 2.6.15 or later.<br>
If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type setattr_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>该函数并未真正实现<br>
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### lookup/5, 查找目录(inode)下某个文件(BName)的属性 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   lookup (Ctx::#fuse_ctx{}, ParentInode::integer (), Name::binary (), Cont::continuation (), State) -&gt; <br>
	   { lookup_async_reply (), NewState } | { noreply, NewState }<br>
   lookup_async_reply () = #fuse_repoply_entry{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Lookup a directory entry by name and get its attributes.  Returning<br>
an entry with inode zero means a negative entry which is cacheable, whereas<br>
an error of enoent is a negative entry which is not cacheable.<br>
If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type lookup_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据目录的inode查找该文件夹的Path;<br />
根据Path调用egfs:listdir得到该目录的全部子文件/夹；<br />
如果名字为Name的子文件/夹存在，就调用egfs:read_file_info, 得到属性,并返回给fuse;<br />
如果不存在，则返回{#fuse_reply_err{err=enoent}, State}.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### create/7, 创建一个文件，并将之打开 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   create (Ctx::#fuse_ctx{}, Parent::integer (), Name::binary (), Mode::create_mode (), <br>
	       Fi::#fuse_file_info{}, Cont::continuation (), State) -&gt; <br>
        { create_async_reply (), NewState } | { noreply, NewState } <br>
   create_async_reply () = #fuse_reply_create{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Create and open a file.<br>
Mode is a bitmask consisting of ?S_XXXXX macros portably defined in fuserl.hrl .<br>
If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type create_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据Parent(Inode)得到父目录的全路径，然后与Name组合，得到待建文件的全路径Path;<br />
调用egfs:open以write方式打开Path, 然后立即关闭，完成文件的创建；<br />
调用egfs:open以append方式再次打开Path, 把得到的{Handle, WorkerPid}存入egfsrv.pids;<br />
把文件的handle以及属性返回给fuse.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### unlink/5, 删除目录(Inode)下的一个文件(Name) ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   unlink (Ctx::#fuse_ctx{}, Inode::integer (), Name::binary (), Cont::continuation (), State) -&gt; <br>
        { unlink_async_reply (), NewState } | { noreply, NewState }<br>
   unlink_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Remove a file.  #fuse_reply_err{err = ok} indicates success.<br>
If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type unlink_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据Inode获得父目录的全路径, 然后与Name组合得到待删文件的全路径Path；<br />
调用egfs:delete, 删除Path;<br />
清除Path在全局变量中的信息(egfsrv.inode, egfsrv.names);<br />
返回{#fuse_reply_err{err = ok}, NewState}.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### open/5, 以Fi中指定的mode打开Inode对应的文件 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   unlink (Ctx::#fuse_ctx{}, Inode::integer (), Name::binary (), Cont::continuation (), State) -&gt; <br>
        { unlink_async_reply (), NewState } | { noreply, NewState }<br>
   unlink_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Open an inode. If noreply is used, eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2}<br>
should be called with Cont as first argument and the second argument of type<br>
open_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据Inode获得待打开文件的全路径Path；<br />
调用egfs:open，打开文件Path, 获得相应的(Handle, WorkerPid);<br />
将(Handle, WorkerPid)值对存入egfsrv.pids；再将Handle及其他信息返回给fuse.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### release/5, 关闭Inode对应的文件 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   release(Ctx::#fuse_ctx{}, Inode::integer(), Fi::#fuse_file_info{}, Cont::continuation(), State) -&gt; <br>
		{ release_async_reply (), NewState } | { noreply, NewState } <br>
   release_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Called when there are no more references to a file.<br>
For every {@link open/4. open} call there is exactly one release call.<br>
Fi#fuse_file_info.fh will contain the descriptor set in {@link open/4. open}, if any.<br>
Fi#fuse_file_info.flags will contain the same flags as for {@link open/4. open}.<br>
</blockquote><ol><li>use_reply_err{err = ok} indicates success.<br>
</li></ol><blockquote>Errors are not reported anywhere; use {@link flush/4. flush} for that.<br>
If noreply is used,<br>
<blockquote>eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type release_async_reply ().<br>
</blockquote></blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>只使用到了Fi参数，根据Fi.fh, 查找egfsrv.pids，得到相应的WorkerPid;<br />
<blockquote>调用egfs.close(WorkerPid);<br />
删除egfsrv.pids中相应的信息.<br />
</blockquote></blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### read/7, 在Fi.fh对应的文件中，读取从Offset开始Size个字节的内容. ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   read (Ctx::#fuse_ctx{}, Inode::integer (), Size::integer (), Offset::integer (), <br>
	     Fi::#fuse_file_info{}, Cont::continuation (), State) -&gt; <br>
       { read_async_reply (), NewState } | { noreply, NewState }<br>
   read_async_reply () = #fuse_reply_buf{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Read Size bytes starting at offset Offset. The file descriptor and other flags are available in Fi.<br>
If noreply is used,<br>
<blockquote>eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type read_async_reply ().<br>
</blockquote></blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>只用到Size, Offset, Fi和State参数；<br />
根据Fi.fh查找egfsrv.pids得到相应的WorkerPid;<br />
根据WorkerPid调用egfs:pread，读取相应的内容.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### write/7, 将Data写入Fi.fh中指定的位置 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   write(Ctx::#fuse_ctx{}, Inode::integer (), Data::binary (), Offset::integer (), <br>
	     Fi::#fuse_file_info{}, Cont::continuation (), State) -&gt; <br>
       { write_async_reply (), NewState } | { noreply, NewState }<br>
   write_async_reply () = #fuse_reply_write{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Write data to a file. If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type write_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>只用到Data, Offset, Fi和State参数;<br />
根据Fi.fh查找egfsrv.pids得到相应的WorkerPid;<br />
根据WorkerPid调用egfs:write，将Data写入.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### flush/5, 将缓冲区内容写入文件 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   flush(Ctx::#fuse_ctx{}, Inode::integer(), Fi::#fuse_file_info{}, Cont::continuation(), State) -&gt; <br>
       { flush_async_reply (), NewState } | { noreply, NewState } <br>
   flush_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>This is called on each close () of an opened file, possibly multiple times per open/4 call<br>
(due to dup() et. al.).<br>
Fi#fuse_file_info.fh will contain the descriptor set in open/4, if any.<br>
</blockquote><ol><li>use_reply_err{err = ok} indicates success.<br>
</li></ol><blockquote>This return value is ultimately the return value of close () (unlike release/4).<br>
Does <b>not</b> necessarily imply an fsync.<br>
If noreply is used,<br>
<blockquote>eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type flush_async_reply ().<br>
</blockquote></blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>该函数并未真正实现.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### rename/7，将Parent下的文件/夹Name移到NewParent下,名字改为NewName ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   rename (Ctx::#fuse_ctx{}, Parent::integer (), Name::binary (), NewParent::integer (), <br>
	       NewName::binary (), Cont::continuation (), State) -&gt; <br>
       { rename_async_reply (), NewState } | { noreply, NewState }<br>
   rename_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Rename a file.  #fuse_reply_err{err = ok} indicates success.<br>
If noreply is used,<br>
<blockquote>eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type rename_async_reply ().<br>
</blockquote></blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据Parent及Name得到源文件的Path;<br />
根据NewParent及NewName得到目的文件的NewPath;<br />
调用egfs:move, 实现文件的重命名;<br />
清除egfsrv.inodes, egfsrv.names中对应Path的信息;<br />
添加egfsrv.inodes, egfsrv.names中NewPath的信息.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### mkdir/6, 在目录ParentInode下创建新目录(Name) ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   mkdir (Ctx::#fuse_ctx{}, ParentInode::integer (), Name::binary (), Mode::stat_mode (), <br>
	      Cont::continuation (), State) -&gt; <br>
       { mkdir_async_reply (), NewState } | { noreply, NewState }<br>
   mkdir_async_reply () = #fuse_reply_entry{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Make a directory.  Mode is a mask composed of the ?S_XXXXX macros<br>
which are (portably) defined in fuserl.hrl.<br>
If noreply is used,<br>
<blockquote>eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type mkdir_async_reply ().<br>
</blockquote></blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据ParentInode查到待建目录的父目录全路径，与Name组合，得到待建全路径Path;<br />
调用egfs:mkdir建立新目录;<br />
把新目录的(inode, Path)值对加入egfsrv.inodes和egfsrv.names;<br />
获取新目录的属性，返回给fuse.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### rmdir/5, 删除Inode下名字为Name的目录 ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   rmdir (Ctx::#fuse_ctx{}, Inode::integer(), Name::binary(), Cont::continuation(), State) -&gt; <br>
       { rmdir_async_reply (), NewState } | { noreply, NewState }<br>
   rmdir_async_reply () = #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Remove a directory.  #fuse_reply_err{err = ok} indicates success.<br>
If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont as first argument<br>
and the second argument of type rmdir_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>根据ParentInode查到待删目录的父目录全路径，与Name组合，得到待删全路径Path;<br />
调用egfs:deldir删除对应目录;<br />
把该目录的(inode, Path)信息从egfsrv.inodes和names中清除;<br />
返回{#fuse_reply_err{err = ok, NewState}给fuse;<br />
把新目录的(inode, Path)值对加入egfsrv.inodes和egfsrv.names.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

> #### readdir/7, 获取目录Inode下所有文件的属性及其对应的inode ####
<p>
<blockquote><div>
<ul><li>定义<br>
</li></ul><blockquote>@spec<br>
<pre><code>   readdir (Ctx::#fuse_ctx{}, Inode::integer (), Size::integer (), Offset::integer (), <br>
	        Fi::#fuse_file_info{}, Cont::continuation (), State) -&gt; <br>
        { readdir_async_reply (), NewState } | { noreply, NewState }<br>
   readdir_async_reply () = #fuse_reply_direntrylist{} | #fuse_reply_err{}<br>
</code></pre>
@doc<br>
<blockquote>Get the file attributes associated with an inode.  If noreply is used,<br>
eventually {@link fuserlsrv:reply/2. fuserlsrv:reply/2} should be called with Cont<br>
as first argument and the second argument of type getattr_async_reply ().<br>
</blockquote>@end<br>
</blockquote><ul><li>实现细节<br>
<blockquote>实现最复杂的一个函数<br />
首先获取"." ".."两个特殊子目录的属性 ＋ inode；<br />
然后获取其常规子文件(或文件夹)的属性 + inode;<br />
接着把两者合并起来，转换成fuse所需要的格式，返回给fuse.<br />
</blockquote></li></ul><blockquote></div>
</p></blockquote></blockquote>

**备注**
@spec等英文部分是从fuserl.erl中摘录的，各函数中#fuse