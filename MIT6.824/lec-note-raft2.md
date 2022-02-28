http://nil.csail.mit.edu/6.824/2020/notes/l-raft2.txt
# topic: persistence (Lab 2C)
## server crash后应该怎么办
1. 使用empty server代替
	- 需要将整个日志或者snapshot传输到new server
	- 虽然很慢，但是也要实现，避免crash是永久的
2. 重启server并重新恢复状态 
	- 需要持久化状态，避免多台机器同时断电
## server reboot后恢复正常需要持久化什么
- Figure 2：`log[]`, currentTerm, votedFor
- votedFor：避免投票后重启在同一term内又投票给另外一个candidate
- currentTerm：确保term是递增的（如果不记录的话reboot后可能会使用了别的server的旧term number），并且用来检测leader和candidate的RPC请求
- 何时保存：状态发生改变后或者在发送RPC和接收RPC之前
## 为什么不需要保存这些状态
- commitIndex, lastApplied, `next/matchIndex[]`
- leader可以通过自身的log和Append Entries RPC回复的信息推断出上述的状态
## 持久化通常是性能的瓶颈
- hard disk write: 10ms, SSD write: 0.1ms, 所以操作数限制在100~10000 ops/second
- 潜在的瓶颈：RPC（<< 1ms on LAN）[Much less than](https://math.stackexchange.com/questions/1516976/much-less-than-what-does-that-mean)
- 解决方法：批量写入、写入battery-backed RAM而不是disk
## server crash+reboot后怎么恢复正常
- 简单方法：re-play整个持久化日志（从0开始）
- faster：使用snapshot
# topic: log compaction and Snapshots (Lab 3B)
## 问题
- log可能变得很大
- 进而导致re-play或者发送log可能需要很多时间
## 我们只需要保存service state
![[Pasted image 20220226163657.png]]
- clients only see the state, not the log
- service state通常小得多，只需要保存这个即可
## 解决方案：service定期保存snapshot
![[Pasted image 20220226164026.png]]
1. copy service state，例如上面的k/v table
2. service将snapshot持久化到磁盘，同时记录着对应的log index，比如上图的3
3. raft丢弃log index为3之前的log
4. service可以随时创建snapshot并告诉raft丢弃log
- raft可能都不知道snapshot的存在和里面的内容是什么，因为snapshot存的内容都是与service相关的。
## crash+restart后怎么恢复
1. service从磁盘中读取snapshot
2. raft从磁盘中读取persisted log
3. service告诉raft将lastApplied设置为snapshot保存时对应的log index
## 问题：leader缺少发送给follower的日志
![[Pasted image 20220227122714.png]]
- follower offline并且snapshot后leader丢失了一些log
- leader不能用AppendEntriesRPC，应该额外使用InstallSnapshot RPC
# linearizability
- 等同于strong consistency
https://www.anishathalye.com/2017/06/04/testing-distributed-systems-for-linearizability/
## linearizability definition
针对于`execution history`（其实就是client request history，每个操作都有参数、返回值、开始时间、完成时间）：
1. 历史中的每个操作都是有序的，一个接一个
2. 如果一个操作在另一个操作开始前结束，这个先结束的操作会先落地到历史中
3. 如果某个读请求看到了一个特定的写入值，那么这个读请求必然在对应的写请求之后
## EX1
![[Pasted image 20220228213422.png]]
`|- Wx1 -|`：`|-`代表client发出request，`-|`代表收到response，`Wx1`代表write操作，将x设置为1
1. 根据第二点，先结束的落到历史
2. 根据第三点，读到x=2，那么肯定是先设置x=2
3. 同理第三点
4. 根据图，先有x=1，再有x=2
所以整个操作历史是`Wx1 Rx1 Wx2 Rx2`，是linearizable history
## EX2
![[Pasted image 20220228215715.png]]
4. Rx1应该在Wx1后，但是严格的讲，Rx1应该在Wx2的前面，如果Wx2在Rx1之前出现，那么就不可能有Rx1了
234形成一个环，所以不是是linearizable
## EX3
![[Pasted image 20220228222051.png]]
```
Wx0 Wx1
Wx2 Rx2
Rx2 Rx1
Wx1 Rx1
order: Wx0 Wx2 Rx2 Wx1 Rx1
```

这里可以看出write操作是可以并发的
# duplicate RPC detection (Lab 3)
