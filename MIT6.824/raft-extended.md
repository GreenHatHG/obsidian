# Raft
- Raft是什么
	- [[raft-extended-annotation#^hhf15v1r3do|Raft is a consensus algorithm for managing a replicated log.]]
	- [Consensus](https://en.wikipedia.org/wiki/Consensus_(computer_science): 在存在许多faulty process的情况下实现整体系统的可靠性
- Raft将四部分拆解以提高可理解性：
	- Leader election
	- Log replication
	- Safety
	- State space reduction
# Replicated state machines
![[Pasted image 20220127213517.png]]
- Replicated state machines用于解决分布式系统中[fault tolerance](https://en.wikipedia.org/wiki/Fault_tolerance)问题，常用来管理leader election和存储必要的数据以让leader崩溃后正常恢复。
- 通常使用replicated log实现
- 每个server存储着log，log中最主要的内容是command。每个state machine按照相同的顺序执行相同命令，产生相同的输出。
- Consensus module接收client的命令，并添加到其log中。它会与其他server上的该module进行通信，确保每个server上log中的command都一致。一旦command被正确的复制，每个server的state machine将按照同样的顺序处理command。然后返回结果给client。
- Consensus algorithm通常具有以下特性：
	- 在[non-Byzantine](https://en.wikipedia.org/wiki/Byzantine_fault)条件下，network delays, partitions, and packet loss, duplica-tion, and reordering都能保证safety。
	- 只要majority of the servers在运行，并且彼此（包括client）能够通信，系统就能正常运行。
	- 不依赖时间确保log的一致性，但是在极端情况下，faulty clocks and extreme message  delays会导致极端问题。
	- 少数slow server不会影响系统性能
# Raft consensus algorithm
- 用来管理上述提到的replicated log
- 实现consensus的思路：
	1. 选取一个leader，让leader管理replicated log
	2. Leader接收client的log entries
	3. Leader将其复制到其他server上
	4. 通知server可以安全地apply log entries到state machines
- 为此，可以将consensus问题拆解成三部分：
	- Leader election：选取leader和leader fails时重新选举
	- Log replication：接收Log entries、复制到其他server、保持log一致性。
	- Safety：state machine safety property
## Raft basics
### 三种server状态
![[Pasted image 20220128115316.png]]
- 每个server共有三种状态：leader、follower、candidate
- 正常运行时候只有一个leader，其他都是follower。
- Follower只接收来自leader和candidate的request，自己不会发出任何request。
- 如果一段时间内follower没有收到任何信息，就会变成candidate，并发起Leader election。
- Candidate从所有成员中获得majority vote就能成为新的leader
- Leader一直工作到fail为止。
### Term
![[Pasted image 20220128115801.png]]
- 一个term代表一个任意时间段，用连续整数序号表示，每个term以Leader election开始，一个或多个candidate试图成为leader。
- Election可能会导致spilt vote，这时候该term会以没有leader结束，一个term最多有一个leader。
- Term用来检测过时的信息，每个server存储着current term编号。
- 在server之间通信时候会交换current term。如果一个candidate或者leader发现它的term过时了，它会立即恢复到follower状态。
- 每个server不会处理过时的request
### RPC
- 每个server之间使用RPC进行通信
- 基本的算法只需要两种RPC
	- RequestVote RPC：在选举时候由candidate发起
	- AppendEntries RPC：由leader发起，提供复制log和heartbeat（没有log entries）功能
- Snapshot RPC用于在server之间传输snapshot（优化）
## Leader election
### 发起election
- Server启动的时候，状态为follower。只要接收到来自leader或者candidate有效的RPC时候，就会保持follower这个状态。
- Leader定期向所有follower发送heartbeat以维持follower的状态。
- 如果follower在一段时间内（这段时间称为election timeout）没有收到任何请求，就会发起leader election。
### election过程
- 递增当前term->转变为candidate->自己给自己投一票->并行向其他server发出RequestVote RPC
- Candidate一直处于上面的流程直到下面某一件事发生：
	- 它赢得了选举
	- 另外一个server成为了leader
	- 一段时间过去了没有winer
### 选举成功
- 成为leader：candidate从所有成员中获取了majority vote（确保最多只有一个leader）
- 每个server在一个term内只能投一次票（按照先到先得的原则，后续添加了个vote restriction验证）
- 成为leader后向其他server发送heartbeat，防止新的选举产生
###  另外一个server成为了leader
- Election时候可能会收到来自leader的AppendEntries RPC，如果leader的term至少和candidate的term一样大，那么candidate就会回到follower状态。
- 如果小于，则拒绝该RPC请求，保持在candidate状态。
### 一段时间过去了没有winer
- 如果许多follower同时成为candidate，可能会出现spilt vote，导致没有一个candidate获取majority vote。
- 此时，每个candidate启动新一轮election。并且需要额外的措施，否则spilt vote可能一直重复下去。
- Raft使用randomized election timeout确保大多数情况下只有一个follower发起election成为leader，并在其他server超时之前发送heartbeat。
- 同样也可以处理spilt vote。每个candidate开始election之前重置自己的election timeout，降低了下一次出现split vote的可能性。
## Log replication
### replication流程
1. Leader接收client发送包含command的request
2. Leader将command作为new entry添加到log中
3. 并行地向其他server发出AppendEntries RPC
4. Safely replicate entry后，leader将entry apply到state machines
5. 返回执行结果给client
- 如果出现followers crash or run slowly,  network packets are lost, leader将无限期重试AppendEntries RPC（即使已经响应client），直到所有的follower replicate log
### log entry
每个server中

