# 概要 #

一个最基本的分布式文件系统。支持单用户写（append）、多用户读，无副本备份，无各种高级特性（如动态副本迁移以解决热点问题等）的分布式文件系统。

# 细节描述 #

## 客户端api ##

  * 客户端api只支持erlang api，没有其他语言的binding。详细规格参阅：[Specification](Specification.md)。

## open ##

  * 支持 read, write（即create）两种模式打开文件。append 暂时不考虑。
  * Writer 写的数据只有在 sync 后，Reader 才能够 read 出来数据。

## write ##

  * 支持单Client写。
  * 无副本。
  * 支持 sync 以使得 Reader 在不重新 open 文件即可读到数据。

## read ##

  * 支持移动读指针（position）。