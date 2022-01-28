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
- Replicated state machines用于解决分布式系统中[fault tolerance](https://en.wikipedia.org/wiki/Fault_tolerance)问题，常用来管理leader election和存储必要的数据以让Leader崩溃后正常恢复。
- 通常使用replicated log实现
- 每个server存储着log，log由许多个command组成。每个state machine按照相同的顺序执行相同命令，产生相同的输出。
- Consensus module接收client的命令，并添加到其log中。它会与其他server上的该module进行通信，确保每个server上的log都包含着相同的command序列。一旦command被正确的复制，每个server的state machine将按照同样的顺序处理command。然后返回结果给client。
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
	- AppendEntries RPC：由leader发起，提供复制log和heartbeat功能
- Snapshot RPC用于在server之间传输snapshot（优化）
## Leader election



