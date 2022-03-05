# ZooKeeper提出了什么问题
1. 能够将coordination作为一种通用服务去提供吗，可以的话，API应该是怎么样的，其他分布式程序应该怎么去使用它？
2. 我们有N个replica server，能从这个N个server中获得N倍性能吗？
# 将ZooKeer视为基于Raft的service
![[Pasted image 20220305160645.png]]
只不过ZooKeeper使用的是zab协议，为ZooKeeper专门设计的一种支持崩溃恢复的一致性协议
# 当我们添加更多的server时候，replication arrangement是否变得更快
replica越多，写入的速度就越慢
leader必须将每次写入发送给越来越多的server
# 可以让follower提供只读服务，这样leader压力就小很多
可能会产生log与leader不一致的情况，这个就不可能是Linearizability
