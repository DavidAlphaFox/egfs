# 里程碑 #

在开发前，我们应该明确下一个“里程碑”是什么样子的，它是项目进展过程中的一个“基准点”。里程碑最重要的点就是决定各个“需求点”何时被支持。

# 规范约定 #

  1. 目录结构规范。
  1. 命名规范。
  1. ...

# 实现某个功能 #

  1. 第0步：发起任务。任何一个功能开始前，均需要发起一个 Type-Task 类型的Issue。
  1. 第1步：进行“模块设计”。包括：
    * “需求分析”，评估这个功能的影响面。
    * “模块接口设计”，明确模块之间的关系（至关重要）。
    * “实现要点陈述”，描述该模块实现中的关键点。
    * “测试要点陈述”，描述该模块需要在哪些地方进行单元测试案例的覆盖。
  1. 设计评审。经过几轮确认过程，最终设计获得认同才可以进入编码（非常重要）。
  1. 编码。每天都至少 checkin 一次自己对代码的修改（如果有的话），并对此次修改进行陈述。详细过程见下一节：“代码入库”。
  1. 代码审查。每一次代码入库（checkin）均应邀请相关模块人员（至少一人）对 checkin 的代码进行 Review。该模块人员给出 Review 结论。
  1. 单元测试（如果设计时指示需要单元测试的话）。
  1. 提交模块。

# 代码入库 #

我们使用的是 svn + trac 系统。这个系统简单易用，而用功能强大。

svn 的 checkin 命令为：svn ci -m "log message"

我们建议 log message 的标准格式为：

```
issue #XXX: 本次修改的主体内容
```

其中 XXX 是本次 checkin 的代码对应的 Issue 号。这样，google code 就会把本次修和 issue #XXX 关联（建立一个超级连接）。


如果 checkin 成功，svn 会提示：

Committed revision YYY.

也就是说，本次提交的代码对应的版本号为 YYY。

此时，你不应该认为一切已经完成了。我们建议你到对应的 issue #XXX 页面（即：http://code.google.com/p/egfs/issues/detail?id=XXX ），在这里建议你将刚才 log message 的内容再重新写一遍（或者更好的做法是，写得更加详细一点）。我们建议的标准格式是：

```
rYYY: 本次修改的主体内容（详细描述）
```

其中 rYYY 中的 YYY，就是前面提交代码时生成的版本号。当你写上 rYYY: 时，google code 会自动生成一个超级连接，指向修改的代码。

以上这些工作应该习惯的去做。

到这里仍然没有完，有了以上这几点，你就可以邀请其他人给你 Review 代码了。

# 代码审查 #

邀请其他人给你 Review 代码时，只需要发给他以下两个 URL 之一：

  * http://code.google.com/p/egfs/issues/detail?id=XXX
  * http://code.google.com/p/egfs/source/detail?r=YYY

然后，Review 人员就可以在 http://code.google.com/p/egfs/source/detail?r=YYY 页面中给出自己的 Review 意见了。