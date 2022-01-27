# Raft
- Raft是什么
	- [[raft-extended-annotation#^hhf15v1r3do|Raft is a consensus algorithm for managing a replicated log.]]
	- [consensus](https://en.wikipedia.org/wiki/Consensus_(computer_science): 在存在许多faulty process的情况下实现整体系统的可靠性
- Raft将四部分拆解以提高可理解性：
	- leader election
	- log replication
	- safety
	- state space reduction
# Replicated state machines
![[Pasted image 20220127213517.png]]
- replicated state machines用于解决分布式系统中[fault tolerance](https://en.wikipedia.org/wiki/Fault_tolerance)问题，常用来管理leader election和存储必要的数据以让Leader崩溃后正常恢复。
- 每个server
