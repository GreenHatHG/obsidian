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
- replicated state machines用于解决分布式系统中[fault tolerance](https://en.wikipedia.org/wiki/Fault_tolerance)问题，常用来管理leader election和存储必要的数据以让Leader崩溃后正常恢复。
- 通常使用replicated log实现
- 每个server存储着log，log由许多个command组成。每个state machine按照相同的顺序执行相同命令，产生相同的输出。
- consensus module接收client的命令，并添加到其log中。它会与其他server上的该module进行通信，确保每个server上的log都包含着相同的command序列。一旦command被正确的复制，每个server的state machine将按照同样的顺序处理command。然后返回结果给client。
- consensus algorithm通常具有以下特性：
	- 在[non-Byzantine](https://en.wikipedia.org/wiki/Byzantine_fault)条件下，network delays, partitions, and packet loss, duplica-tion, and reordering都能保证safety。
	- 只要majority of the servers在运行，并且彼此（包括client）能够通信，系统就能正常运行。
	- 不依赖时间确保log的一致性，但是在极端情况下，faulty clocks and extreme message  delays会导致极端问题。
	- 少数slow server不会影响系统性能
# Raft consensus algorithm
- 用来管理上述提到的replicated log
- 实现consensus的思路：
	1. 选取一个leader，让leader管理replicated log
	2. leader接收client的log entries
	3. leader将其复制到其他server上
	4. 通知server可以安全地apply log entries到state machines
- 为此，可以将consensus问题拆解成三部分：
	- Leader election：选取leader和leader fails时重新选举
	- Log replication：接收Log entries、复制到其他server、保持log一致性
	- Safety：state machine safety property

