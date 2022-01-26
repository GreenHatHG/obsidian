6.824 2020 Lecture 7: Raft (2)
6.824 2020第7讲：木筏（2）

 topic: the Raft log (Lab 2B)
主题：木筏日志（实验2B）

as long as the leader stays up:
  clients only interact with the leader
  clients can't see follower states or logs
只要领导不睡觉：
客户只与领导者互动
客户端无法看到跟随者状态或日志

things get interesting when changing leaders
  e.g. after the old leader fails
  how to change leaders without anomalies?
    diverging replicas, missing operations, repeated operations, &c
当更换领导人时，事情变得有趣起来
e、 g.在老领导失败后
如何在没有异常的情况下更换领导者？
分散的副本、缺失的操作、重复的操作，&c

what do we want to ensure?
  if any server executes a given command in a log entry,
    then no server executes something else for that log entry
  (Figure 3's State Machine Safety)
  why? if the servers disagree on the operations, then a
    change of leader might change the client-visible state,
    which violates our goal of mimicing a single server.
  example:
    S1: put(k1,v1) | put(k1,v2) 
    S2: put(k1,v1) | put(k2,x) 
    can't allow both to execute their 2nd log entries!
我们想确保什么？
如果任何服务器执行日志项中的给定命令，
然后没有服务器为该日志条目执行其他操作
（图3的状态机安全性）
为什么？如果服务器在操作上存在分歧，则
领导者的变更可能会改变客户端的可见状态，
这违反了我们模拟单一服务器的目标。
例子：
S1:put（k1，v1）| put（k1，v2）
S2:put（k1，v1）| put（k2，x）
不能让两个都执行第二个日志条目！

how can logs disagree after a crash?
  a leader crashes before sending last AppendEntries to all
    S1: 3
    S2: 3 3
    S3: 3 3
  worse: logs might have different commands in same entry!
    after a series of leader crashes, e.g.
        10 11 12 13  <- log entry #
    S1:  3
    S2:  3  3  4
    S3:  3  3  5
崩溃后日志怎么会不一致？
在将最后一个附加条目发送给所有
S1:3
S2:3
S3:3
更糟的是：日志在同一个条目中可能有不同的命令！
在一系列领导者崩溃后，例如。
10 11 12 13<-日志条目#
S1:3
S2:34
S3:35

Raft forces agreement by having followers adopt new leader's log
  example:
  S3 is chosen as new leader for term 6
  S3 sends an AppendEntries with entry 13
     prevLogIndex=12
     prevLogTerm=5
  S2 replies false (AppendEntries step 2)
  S3 decrements nextIndex[S2] to 12
  S3 sends AppendEntries w/ entries 12+13, prevLogIndex=11, prevLogTerm=3
  S2 deletes its entry 12 (AppendEntries step 3)
  similar story for S1, but S3 has to back up one farther
Raft通过让追随者采用新领导人的日志来强制达成协议
例子：
S3被选为第六学期的新领导
S3发送带有条目13的附加条目
prevLogIndex=12
prevLogTerm=5
S2回复错误（第2步）
S3将nextIndex[S2]递减至12
S3发送带有条目12+13、prevLogIndex=11、prevLogTerm=3的附加条目
S2删除其条目12（第3步）
S1的情况类似，但S3必须再备份一个

the result of roll-back:
  each live follower deletes tail of log that differs from leader
  then each live follower accepts leader's entries after that point
  now followers' logs are identical to leader's log
回滚的结果是：
每个活动的跟随者都会删除与引导者不同的日志尾部
然后，每个现场跟随者在该点之后接受领导者的输入
现在追随者的日志与领导者的日志相同

Q: why was it OK to forget about S2's index=12 term=4 entry?
问：为什么可以忘记S2的索引=12项=4项？

could new leader roll back *committed* entries from end of previous term?
  i.e. could a committed entry be missing from the new leader's log?
  this would be a disaster -- old leader might have already said "yes" to a client
  so: Raft needs to ensure elected leader has all committed log entries
新领导人能否从上一个任期结束时撤回*已提交*的条目？
i、 e.新领导的日志中是否会缺少一个承诺的条目？
这将是一场灾难——老领导可能已经对客户说了“是”
所以：Raft需要确保当选领导人拥有所有提交的日志条目

why not elect the server with the longest log as leader?
  example:
    S1: 5 6 7
    S2: 5 8
    S3: 5 8
  first, could this scenario happen? how?
    S1 leader in term 6; crash+reboot; leader in term 7; crash and stay down
      both times it crashed after only appending to its own log
    Q: after S1 crashes in term 7, why won't S2/S3 choose 6 as next term?
    next term will be 8, since at least one of S2/S3 learned of 7 while voting
    S2 leader in term 8, only S2+S3 alive, then crash
  all peers reboot
  who should be next leader?
    S1 has longest log, but entry 8 could have committed !!!
    so new leader can only be one of S2 or S3
    i.e. the rule cannot be simply "longest log"
为什么不选择日志最长的服务器作为领导者？
例子：
S1:567
S2:58
S3:58
首先，这种情况会发生吗？怎样
第六学期的S1领导；崩溃+重启；第七学期的领导者；趴下
两次都是在添加到自己的日志后崩溃的
问：在第七学期S1崩溃后，为什么S2/S3不选择第六学期作为下一学期？
下一个学期将是8，因为S2/S3中至少有一人在投票时学会了7
第八学期S2领先，只有S2+S3还活着，然后崩溃
所有对等机重新启动
谁应该是下一任领导人？
S1有最长的日志，但条目8可能已提交！！！
所以新的领导者只能是S2或S3中的一个
i、 e.规则不能只是“最长日志”

end of 5.4.1 explains the "election restriction"
  RequestVote handler only votes for candidate who is "at least as up to date":
    candidate has higher term in last log entry, or
    candidate has same last term and same length or longer log
  so:
    S2 and S3 won't vote for S1
    S2 and S3 will vote for each other
  so only S2 or S3 can be leader, will force S1 to discard 6,7
    ok since 6,7 not on majority -> not committed -> reply never sent to clients
    -> clients will resend the discarded commands
5.4.1结尾解释了“选举限制”
RequestVote handler只为“至少是最新的”候选人投票：
候选人在最后一个日志条目中有更高的期限，或
候选人有相同的最后任期和相同的长度或更长的日志
所以：
S2和S3不会投票给S1
S2和S3将相互投票
所以只有S2或S3可以作为前导，这将迫使S1放弃6,7
好的，因为6,7不在多数->未提交->回复从未发送给客户
->客户端将重新发送丢弃的命令

the point:
  "at least as up to date" rule ensures new leader's log contains
    all potentially committed entries
  so new leader won't roll back any committed operation
重点是：
“至少是最新的”规则确保新领导的日志包含
所有可能提交的条目
所以新领导人不会撤回任何承诺的行动

The Question (from last lecture)
  figure 7, top server is dead; which can be elected?
问题（来自上节课）
图7，顶级服务器已关闭；谁能当选？

depending on who is elected leader in Figure 7, different entries
  will end up committed or discarded
  some will always remain committed: 111445566
    they *could* have been committed + executed + replied to
  some will certainly be discarded: f's 2 and 3; e's last 4,4
  c's 6,6 and d's 7,7 may be discarded OR committed
根据图7中谁当选领导人，不同的条目
最终将被投入或抛弃
有些人将永远保持承诺：111445566
他们可能已经被提交、执行、回复
有些肯定会被丢弃：f的2和3；e的最后4,4
c的6,6和d的7,7可能会被丢弃或犯下

how to roll back quickly
  the Figure 2 design backs up one entry per RPC -- slow!
  lab tester may require faster roll-back
  paper outlines a scheme towards end of Section 5.3
    no details; here's my guess; better schemes are possible
      Case 1      Case 2       Case 3
  S1: 4 5 5       4 4 4        4
  S2: 4 6 6 6 or  4 6 6 6  or  4 6 6 6
  S2 is leader for term 6, S1 comes back to life, S2 sends AE for last 6
    AE has prevLogTerm=6
  rejection from S1 includes:
    XTerm:  term in the conflicting entry (if any)
    XIndex: index of first entry with that term (if any)
    XLen:   log length
  Case 1 (leader doesn't have XTerm):
    nextIndex = XIndex
  Case 2 (leader has XTerm):
    nextIndex = leader's last entry for XTerm
  Case 3 (follower's log is too short):
    nextIndex = XLen
如何快速回退
图2的设计为每个RPC备份一个条目——慢！
实验室测试仪可能需要更快的回滚
论文在第5.3节末尾概述了一个方案
没有细节；这是我的猜测；更好的计划是可能的
案例1案例2案例3
S1:45444
S2:466或466或466
S2是第六学期的领导者，S1复活，S2为最后六学期发送AE
AE的对数项为6
S1的拒绝包括：
XTerm：冲突条目中的术语（如果有）
XIndex：包含该术语的第一个条目的索引（如果有）
原木长度
案例1（领导者没有XTerm）：
nextIndex=XIndex
案例2（领导者拥有XTerm）：
nextIndex=领导对XTerm的最后一项
案例3（追随者的日志太短）：
nextIndex=XLen

*** topic: persistence (Lab 2C)
***主题：持久性（实验2C）

what would we like to happen after a server crashes?
  Raft can continue with one missing server
    but failed server must be repaired soon to avoid dipping below a majority
  two strategies:
  * replace with a fresh (empty) server
    requires transfer of entire log (or snapshot) to new server (slow)
    we *must* support this, in case failure is permanent
  * or reboot crashed server, re-join with state intact, catch up
    requires state that persists across crashes
    we *must* support this, for simultaneous power failure
    let's talk about the second strategy -- persistence
    服务器崩溃后我们希望发生什么？
    Raft可以在缺少一台服务器的情况下继续
    但出现故障的服务器必须尽快修复，以避免低于多数
    两种策略：
    *替换为新的（空的）服务器
    需要将整个日志（或快照）传输到新服务器（速度较慢）
    我们必须支持这一点，以防失败是永久性的
    *或者重新启动崩溃的服务器，重新加入状态保持不变，赶上进度
    需要在崩溃期间保持的状态
    我们必须支持这一点，因为同时停电
    让我们来谈谈第二种策略——坚持

if a server crashes and restarts, what must Raft remember?
  Figure 2 lists "persistent state":
    log[], currentTerm, votedFor
  a Raft server can only re-join after restart if these are intact
  thus it must save them to non-volatile storage
    non-volatile = disk, SSD, battery-backed RAM, &c
    save after each change -- many points in code
    or before sending any RPC or RPC reply
  why log[]?
    if a server was in leader's majority for committing an entry,
      must remember entry despite reboot, so any future leader is
      guaranteed to see the committed log entry
  why votedFor?
    to prevent a client from voting for one candidate, then reboot,
      then vote for a different candidate in the same (or older!) term
    could lead to two leaders for the same term
  why currentTerm?
    to ensure terms only increase, so each term has at most one leader
    to detect RPCs from stale leaders and candidates
如果服务器崩溃并重新启动，您必须记住什么？
图2列出了“持久状态”：
日志[]，当前术语，votedFor
Raft服务器只有在重新启动后才能重新加入，前提是这些服务器完好无损
因此，它必须将它们保存到非易失性存储器中
非易失性=磁盘、SSD、电池支持的RAM和c
每次更改后保存--代码中有许多点
或者在发送任何RPC或RPC回复之前
为什么要登录[]？
如果一个服务器因为提交条目而在领导者中占多数，
即使重新启动，也必须记住条目，所以任何未来的领导者都是
保证看到提交的日志条目
为什么要投票？
要阻止客户端投票给某个候选人，然后重新启动，
然后在同一选区（或更老的选区）投票给另一位候选人学期
可能会在同一任期内产生两位领导人
为什么是现在这个学期？
确保任期只增加，因此每个任期最多有一名领导人
检测来自过时领导人和候选人的RPC

some Raft state is volatile
  commitIndex, lastApplied, next/matchIndex[]
  why is it OK not to save these?
有些状态是不稳定的
commitIndex，lastApplied，next/matchIndex[]
为什么不保存这些可以？

persistence is often the bottleneck for performance
  a hard disk write takes 10 ms, SSD write takes 0.1 ms
  so persistence limits us to 100 to 10,000 ops/second
  (the other potential bottleneck is RPC, which takes << 1 ms on a LAN)
  lots of tricks to cope with slowness of persistence:
    batch many new log entries per disk write
    persist to battery-backed RAM, not disk
持久性通常是性能的瓶颈
硬盘写入需要10毫秒，SSD写入需要0.1毫秒
所以持久性将我们限制在每秒100到10000次
（另一个潜在的瓶颈是RPC，它在局域网上的时间小于1毫秒）
有很多应对持久性缓慢的技巧：
每次磁盘写入时批处理许多新的日志条目
保存到电池支持的RAM，而不是磁盘

how does the service (e.g. k/v server) recover its state after a crash+reboot?
  easy approach: start with empty state, re-play Raft's entire persisted log
    lastApplied is volatile and starts at zero, so you may need no extra code!
    this is what Figure 2 does
  but re-play will be too slow for a long-lived system
  faster: use Raft snapshot and replay just the tail of the log
在崩溃并重新启动后，服务（如k/v服务器）如何恢复其状态？
简单方法：从空状态开始，重新播放Raft的整个持久日志
lastApplied是易变的，从零开始，所以您可能不需要额外的代码！
图2就是这样做的
但对于一个长期存在的系统来说，重新播放太慢了
更快：使用Raft快照，只回放日志的尾部

*** topic: log compaction and Snapshots (Lab 3B)
***主题：日志压缩和快照（实验室3B）

problem:
  log will get to be huge -- much larger than state-machine state!
  will take a long time to re-play on reboot or send to a new server
问题：
日志将变得巨大——比状态机状态大得多！
重新启动或发送到新服务器时需要很长时间才能重新播放

luckily:
  a server doesn't need *both* the complete log *and* the service state
    the executed part of the log is captured in the state
    clients only see the state, not the log
  service state usually much smaller, so let's keep just that
幸运的是：
服务器不需要*完整日志*和*服务状态
日志的执行部分在状态中被捕获
客户端只查看状态，而不查看日志
服务状态通常要小得多，所以我们就这样吧

what entries *can't* a server discard?
  un-executed entries -- not yet reflected in the state
  un-committed entries -- might be part of leader's majority
哪些条目*不能*服务器丢弃？
未执行的条目——尚未反映在状态中
未提交的条目——可能是领导者多数票的一部分

solution: service periodically creates persistent "snapshot"
  [diagram: service state, snapshot on disk, raft log (same in mem and disk)]
  copy of service state as of execution of a specific log entry
    e.g. k/v table
  service writes snapshot to persistent storage (disk)
    snapshot includes index of last included log entry
  service tells Raft it is snapshotted through some log index
  Raft discards log before that index
  a server can create a snapshot and discard prefix of log at any time
    e.g. when log grows too long
解决方案：服务定期创建持久的“快照”
[图表：服务状态、磁盘上的快照、raft日志（在mem和磁盘中相同）]
执行特定日志项时的服务状态副本
e、 g.k/v表
服务将快照写入持久性存储（磁盘）
快照包括最后包含的日志项的索引
服务告诉Raft它是通过一些日志索引拍摄的
Raft在索引之前丢弃原木
服务器可以随时创建快照并丢弃日志前缀
e、 g.当原木长得太长时

what happens on crash+restart?
  service reads snapshot from disk
  Raft reads persisted log from disk
  service tells Raft to set lastApplied to last included index
    to avoid re-applying already-applied log entries
崩溃+重启时会发生什么？
服务从磁盘读取快照
Raft从磁盘读取持久化日志
服务告诉Raft将lastApplied设置为最后包含的索引
避免重新应用已应用的日志条目

problem: what if follower's log ends before leader's log starts?
  because follower was offline and leader discarded early part of log
  nextIndex[i] will back up to start of leader's log
  so leader can't repair that follower with AppendEntries RPCs
  thus the InstallSnapshot RPC
问题：如果跟随者的日志在领导者的日志开始之前结束呢？
因为跟随者离线，领导者丢弃了日志的早期部分
nextIndex[i]将备份到leader日志的开始
所以领导者不能用RPC修复跟随者
因此，安装快照RPC

philosophical note:
  state is often equivalent to operation history
  you can often choose which one to store or communicate
  we'll see examples of this duality later in the course
哲学笔记：
状态通常相当于操作历史
你通常可以选择存储或交流哪一个
我们将在本课程后面看到这种二元性的例子

practical notes:
  Raft's snapshot scheme is reasonable if the state is small
  for a big DB, e.g. if replicating gigabytes of data, not so good
    slow to create and write to disk
  perhaps service data should live on disk in a B-Tree
    no need to explicitly snapshot, since on disk already
  dealing with lagging replicas is hard, though
    leader should save the log for a while
    or remember which parts of state have been updated
实用说明：
如果状态很小，Raft的快照方案是合理的
对于大型数据库，例如，如果复制千兆字节的数据，则不太好
创建和写入磁盘的速度较慢
也许服务数据应该以B树的形式存在于磁盘上
无需显式快照，因为已在磁盘上
不过，处理滞后的复制品很难
领导应该保存日志一段时间
或者记住州的哪些部分已经更新

*** linearizability
***线性化

we need a definition of "correct" for Lab 3 &c
  how should clients expect Put and Get to behave?
  often called a consistency contract
  helps us reason about how to handle complex situations correctly
    e.g. concurrency, replicas, failures, RPC retransmission,
         leader changes, optimizations
  we'll see many consistency definitions in 6.824
我们需要一个3&c实验室“正确”的定义
客户应该如何期望卖出和卖出？
通常被称为一致性契约
帮助我们思考如何正确处理复杂情况
e、 g.并发、副本、故障、RPC重传、，
领导者的变化、优化
我们将在6.824中看到许多一致性定义

"linearizability" is the most common and intuitive definition
  formalizes behavior expected of a single server ("strong" consistency)
“线性化”是最常见、最直观的定义
形式化单个服务器的预期行为（“强”一致性）

linearizability definition:
  an execution history is linearizable if
    one can find a total order of all operations,
    that matches real-time (for non-overlapping ops), and
    in which each read sees the value from the
    write preceding it in the order.
线性化定义：
执行历史记录可以线性化，如果
可以找到所有操作的总顺序，
实时匹配（对于非重叠操作），以及
在这种情况下，每次读取都会看到
按顺序写在前面。

a history is a record of client operations, each with
  arguments, return value, time of start, time completed
历史记录是客户端操作的记录，每个操作都有
参数、返回值、开始时间、完成时间

example history 1:
  |-Wx1-| |-Wx2-|
    |---Rx2---|
      |-Rx1-|
"Wx1" means "write value 1 to record x"
"Rx1" means "a read of record x yielded value 1"
draw the constraint arrows:
  the order obeys value constraints (W -> R)
  the order obeys real-time constraints (Wx1 -> Wx2)
this order satisfies the constraints:
  Wx1 Rx1 Wx2 Rx2
  so the history is linearizable
示例历史1：
|-Wx1-| |-Wx2-|
|---Rx2---|
|-Rx1-|
“Wx1”表示“将值1写入记录x”
“Rx1”指“读取记录x产生值1”
绘制约束箭头：
订单遵循价值约束（W->R）
订单遵守实时约束（Wx1->Wx2）
该顺序满足以下约束条件：
Wx1 Rx1 Wx2 Rx2
所以历史是可以线性化的

note: the definition is based on external behavior
  so we can apply it without having to know how service works
note: histories explicitly incorporates concurrency in the form of
  overlapping operations (ops don't occur at a point in time), thus good
  match for how distributed systems operate.
注：该定义基于外部行为
所以我们可以应用它，而不必知道服务是如何工作的
注意：历史记录以
重叠操作（操作不会在某个时间点发生），因此很好
与分布式系统的运行方式相匹配。

example history 2:
  |-Wx1-| |-Wx2-|
    |--Rx2--|
              |-Rx1-|
draw the constraint arrows:
  Wx1 before Wx2 (time)
  Wx2 before Rx2 (value)
  Rx2 before Rx1 (time)
  Rx1 before Wx2 (value)
there's a cycle -- so it cannot be turned into a linear order. so this
history is not linearizable. (it would be linearizable w/o Rx2, even
though Rx1 overlaps with Wx2.)
示例历史2：
|-Wx1-| |-Wx2-|
|--Rx2--|
|-Rx1-|
绘制约束箭头：
Wx2之前的Wx1（时间）
Rx2之前的Wx2（值）
Rx1之前的Rx2（时间）
Wx2之前的Rx1（值）
这是一个循环，所以不能转化为线性顺序。所以这个
历史是不可线性化的。（即使没有Rx2，它也可以线性化
尽管Rx1与Wx2重叠。）

example history 3:
|--Wx0--|  |--Wx1--|
            |--Wx2--|
        |-Rx2-| |-Rx1-|
order: Wx0 Wx2 Rx2 Wx1 Rx1
so the history linearizable.
so:
  the service can pick either order for concurrent writes.
  e.g. Raft placing concurrent ops in the log.
示例历史3：
|--Wx0--| |--Wx1--|
|--Wx2--|
|-Rx2-| |-Rx1-|
订单：Wx0 Wx2 Rx2 Wx1 Rx1
所以历史可以线性化。
所以：
该服务可以为并发写入选择任意一个顺序。
e、 g.在原木中放置木筏。

example history 4:
|--Wx0--|  |--Wx1--|
            |--Wx2--|
C1:     |-Rx2-| |-Rx1-|
C2:     |-Rx1-| |-Rx2-|
what are the constraints?
  Wx2 then C1:Rx2 (value)
  C1:Rx2 then Wx1 (value)
  Wx1 then C2:Rx1 (value)
  C2:Rx1 then Wx2 (value)
  a cycle! so not linearizable.
so:
  service can choose either order for concurrent writes
  but all clients must see the writes in the same order
  this is important when we have replicas or caches
    they have to all agree on the order in which operations occur
示例历史4：
|--Wx0--| |--Wx1--|
|--Wx2--|
C1:|-Rx2-| |-Rx1-|
C2:|-Rx1-| |-Rx2-|
制约因素是什么？
Wx2然后C1:Rx2（值）
C1:Rx2然后是Wx1（值）
Wx1然后C2:Rx1（值）
C2:Rx1然后Wx2（值）
循环！所以不能线性化。
所以：
服务可以为并发写入选择任意顺序
但所有客户端必须以相同的顺序查看写入
当我们有副本或缓存时，这一点很重要
他们必须就行动的顺序达成一致

example history 5:
|-Wx1-|
        |-Wx2-|
                |-Rx1-|
constraints:
  Wx2 before Rx1 (time)
  Rx1 before Wx2 (value)
  (or: time constraints mean only possible order is Wx1 Wx2 Rx1)
there's a cycle; not linearizable
so:
  reads must return fresh data: stale values aren't linearizable
  even if the reader doesn't know about the write
    the time rule requires reads to yield the latest data
  linearzability forbids many situations:
    split brain (two active leaders)
    forgetting committed writes after a reboot
    reading from lagging replicas
示例历史5：
|-Wx1-|
|-Wx2-|
|-Rx1-|
限制条件：
Rx1之前的Wx2（时间）
Wx2之前的Rx1（值）
（或：时间限制意味着唯一可能的顺序是Wx1 Wx2 Rx1）
有一个循环；不可线性化
所以：
读取必须返回新数据：过时的值不能线性化
即使读者不知道这篇文章
时间规则要求读取以生成最新数据
线性化禁止许多情况：
分裂的大脑（两个活跃的领导者）
重新启动后忘记已提交的写入
从落后的复制品中阅读

example history 6:
suppose clients re-send requests if they don't get a reply
in case it was the response that was lost:
  leader remembers client requests it has already seen
  if sees duplicate, replies with saved response from first execution
but this may yield a saved value from long ago -- a stale value!
what does linearizabilty say?
C1: |-Wx3-|          |-Wx4-|
C2:          |-Rx3-------------|
order: Wx3 Rx3 Wx4
so: returning the old saved value 3 is correct
示例6：
假设客户机在没有得到回复的情况下重新发送请求
如果失去的是回复：
leader会记住已经看到的客户请求
如果看到重复，则使用第一次执行时保存的响应进行回复
但这可能会产生一个很久以前保存下来的价值——一个过时的价值！
你说什么？
C1:|-Wx3-| |-Wx4-|
C2:|-Rx3-------------|
订单：Wx3 Rx3 Wx4
所以：返回旧的保存值3是正确的

You may find this page useful:
https://www.anishathalye.com/2017/06/04/testing-distributed-systems-for-linearizability/
您可能会发现此页面很有用：
https://www.anishathalye.com/2017/06/04/testing-distributed-systems-for-linearizability/

*** duplicate RPC detection (Lab 3)
***重复RPC检测（实验3）

What should a client do if a Put or Get RPC times out?
  i.e. Call() returns false
  if server is dead, or request dropped: re-send
  if server executed, but request lost: re-send is dangerous
如果Put或Get RPC超时，客户端应该怎么做？
i、 e.Call（）返回false
如果服务器已关闭，或请求已删除：重新发送
如果服务器已执行，但请求丢失：重新发送是危险的

problem:
  these two cases look the same to the client (no reply)
  if already executed, client still needs the result
问题：
这两个案例在客户看来是一样的（没有回复）
如果已经执行，客户端仍然需要结果

idea: duplicate RPC detection
  let's have the k/v service detect duplicate client requests
  client picks an ID for each request, sends in RPC
    same ID in re-sends of same RPC
  k/v service maintains table indexed by ID
  makes an entry for each RPC
    record value after executing
  if 2nd RPC arrives with the same ID, it's a duplicate
    generate reply from the value in the table
想法：重复RPC检测
让k/v服务检测重复的客户端请求
客户端为每个请求选择一个ID，并在RPC中发送
相同RPC的重新发送中的相同ID
k/v服务维护按ID索引的表
为每个RPC创建一个条目
执行后记录值
如果第二个RPC以相同的ID到达，则它是重复的
根据表中的值生成回复

design puzzles:
  when (if ever) can we delete table entries?
  if new leader takes over, how does it get the duplicate table?
  if server crashes, how does it restore its table?
设计难题：
我们什么时候（如果有的话）可以删除表项？
如果新领导接手，它如何获得重复表？
如果服务器崩溃，它如何恢复其表？

idea to keep the duplicate table small
  one table entry per client, rather than one per RPC
  each client has only one RPC outstanding at a time
  each client numbers RPCs sequentially
  when server receives client RPC #10,
    it can forget about client's lower entries
    since this means client won't ever re-send older RPCs
保持复制表小的想法
每个客户端一个表项，而不是每个RPC一个表项
每个客户端一次只有一个未完成的RPC
每个客户端按顺序为RPC编号
当服务器收到客户端RPC#10时，
它可以忘记客户较低的条目
因为这意味着客户端永远不会重新发送旧的RPC

some details:
  each client needs a unique client ID -- perhaps a 64-bit random number
  client sends client ID and seq # in every RPC
    repeats seq # if it re-sends
  duplicate table in k/v service indexed by client ID
    contains just seq #, and value if already executed
  RPC handler first checks table, only Start()s if seq # > table entry
  each log entry must include client ID, seq #
  when operation appears on applyCh
    update the seq # and value in the client's table entry
    wake up the waiting RPC handler (if any)
一些细节：
每个客户机都需要一个唯一的客户机ID——可能是一个64位随机数
客户端在每个RPC中发送客户端ID和seq#
如果重新发送，则重复seq#
k/v服务中按客户端ID索引的重复表
仅包含seq#和值（如果已执行）
RPC处理程序首先检查表，如果seq#>表条目，则只检查Start（）s
每个日志条目必须包括客户端ID，seq#
当操作出现在applyCh上时
更新客户表条目中的seq#和值
唤醒等待的RPC处理程序（如果有）

what if a duplicate request arrives before the original executes?
  could just call Start() (again)
  it will probably appear twice in the log (same client ID, same seq #)
  when cmd appears on applyCh, don't execute if table says already seen
如果重复请求在原始请求执行之前到达，该怎么办？
可以（再次）调用Start（）
它可能会在日志中出现两次（相同的客户端ID，相同的序列号）
当cmd出现在applyCh上时，如果表中显示已看到，则不要执行

how does a new leader get the duplicate table?
  all replicas should update their duplicate tables as they execute
  so the information is already there if they become leader
新领导如何获得重复表？
所有副本都应在执行时更新其重复表
因此，如果他们成为领导者，信息已经存在

if server crashes how does it restore its table?
  if no snapshots, replay of log will populate the table
  if snapshots, snapshot must contain a copy of the table
如果服务器崩溃，它如何恢复其表？
如果没有快照，日志的重播将填充该表
如果是快照，快照必须包含表的副本

but wait!
  the k/v server is now returning old values from the duplicate table
  what if the reply value in the table is stale?
  is that OK?
但是等等！
k/v服务器现在正在从复制表返回旧值
如果表中的回复值过时了怎么办？
可以吗？

example:
  C1           C2
--           --
  put(x,10)
               first send of get(x), 10 reply dropped
  put(x,20)
               re-sends get(x), gets 10 from table, not 20
例子：
C1 C2
--           --
放置（x，10）
第一次发送get（x），10个回复被丢弃
put（x，20）
重新发送get（x），从表中获取10，而不是20

what does linearizabilty say?
C1: |-Wx10-|          |-Wx20-|
C2:          |-Rx10-------------|
order: Wx10 Rx10 Wx20
so: returning the remembered value 10 is correct
你说什么？
C1:|-Wx10-| |-Wx20-|
C2:|-Rx10-------------|
订单：Wx10 Rx10 Wx20
所以：返回记忆值10是正确的

*** read-only operations (end of Section 8)
***只读操作（第8节末尾）

Q: does the Raft leader have to commit read-only operations in
   the log before replying? e.g. Get(key)?
问：木筏负责人是否必须提交只读操作
回复前先查看日志？e、 g.拿到钥匙？

that is, could the leader respond immediately to a Get() using
  the current content of its key/value table?
也就是说，领导者是否可以使用
其键/值表的当前内容？

A: no, not with the scheme in Figure 2 or in the labs.
   suppose S1 thinks it is the leader, and receives a Get(k).
   it might have recently lost an election, but not realize,
   due to lost network packets.
   the new leader, say S2, might have processed Put()s for the key,
   so that the value in S1's key/value table is stale.
   serving stale data is not linearizable; it's split-brain.

so: Figure 2 requires Get()s to be committed into the log.
    if the leader is able to commit a Get(), then (at that point
    in the log) it is still the leader. in the case of S1
    above, which unknowingly lost leadership, it won't be
    able to get the majority of positive AppendEntries replies
    required to commit the Get(), so it won't reply to the client.
答：不，不是图2中的方案，也不是在实验室里。
假设S1认为它是领导者，并得到一个Get（k）。
它可能最近输掉了一场选举，但没有意识到，
由于丢失了网络数据包。
新的领导者，比如S2，可能已经为密钥处理了Put（）s，
这样S1的键/值表中的值就过时了。
提供陈旧数据是不可线性化的；这是分裂的大脑。
因此：图2要求将Get（）提交到日志中。
如果领导者能够提交Get（），那么
在日志中）它仍然是领导者。就S1而言
在不知情的情况下失去了领导地位，这是不会发生的
能够得到大多数正面回复
必须提交Get（），因此它不会回复客户端。

but: many applications are read-heavy. committing Get()s
  takes time. is there any way to avoid commit
  for read-only operations? this is a huge consideration in
  practical systems.
但是：很多应用程序读起来很重。提交Get（）s
需要时间。有没有办法避免犯罪
对于只读操作？这是一个巨大的考虑
实用系统。

idea: leases
  modify the Raft protocol as follows
  define a lease period, e.g. 5 seconds
  after each time the leader gets an AppendEntries majority,
    it is entitled to respond to read-only requests for
    a lease period without commiting read-only requests
    to the log, i.e. without sending AppendEntries.
  a new leader cannot execute Put()s until previous lease period
    has expired
  so followers keep track of the last time they responded
    to an AppendEntries, and tell the new leader (in the
    RequestVote reply).
  result: faster read-only operations, still linearizable.
想法：租赁
修改Raft协议如下
定义租赁期限，例如5秒
每次领袖获得多数后，
它有权对只读请求做出响应
不提交只读请求的租赁期
到日志，即不发送附加条目。
在上一租赁期之前，新领导无法执行Put（）s
已经过期了
所以粉丝们会记录他们最后一次回应的时间
添加条目，并告诉新领导（在
请求投票（回复）。
结果：更快的只读操作，仍然可以线性化。

note: for the Labs, you should commit Get()s into the log;
      don't implement leases.
注意：对于实验室，应该将Get（）提交到日志中；
不要执行租约。

in practice, people are often (but not always) willing to live with stale
  data in return for higher performance

在实践中，人们往往（但并非总是）愿意与陈腐的生活在一起
以数据换取更高的性能

