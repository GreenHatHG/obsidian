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
可能会产生log与leader不一致的情况，导致client读取的数据不对，甚至是产生“倒退现象”，client先从up-to-date replica读，再从logging replica读。这个就不可能是Linearizability
Raft和Lab3不会出现这种情况，因为follower不提供只读服务
# ZooKeeper怎么处理这个
在性能和强一致性之间保持平衡，不提供强一致性，允许从replica读取数据，但是在其他方面则是保证了顺序。
# Ordering guarantees (Section 2.3)
## Linearizable writes
1. client发送写入命令到leader
2. leader选择一个顺序，编号为`zxid`
3. 将该命令发送给replica，所以replica按照zxid顺序去执行。
4. 即使是并发写操作，也会保证按照某个顺序去一一执行。
## FIFO client order
client指定write和read操作的执行顺序
- write：按照client指定的write order，section2.3 ready file
- read：
	- 每次读都在写入顺序中的某一个点开始执行
	- client连续读操作，每次读的顺序保证是非递减，这一次读不会读到前面的内容
	- 如果执行读操作的时候，replica挂掉了，client需要将它的读请求发送给另外一个replica，这时候依旧会保证FIFO client order（非递减）。
	- 工作原理是每个log entry都有一个zxid，当一个replica响应client的读请求时会携带上一个log entry的zxid（这里的上一个相对于是下一个读请求），client会记住最新数据的zxid，每次请求会携带上zxid。
	- 如果另外一个replica也没有最新zxid对应的下一个log，replica可能会延迟对读请求回复直到leader同步了log或者是拒绝这个请求，或者是其他。
- 将write发送给leader，但是leader还没有同步给replica，这时候read replica会被delay（因为指定了命令的执行顺序）或者sync()
- sync：保障写操作，在写数据的时候不允许读，即告诉replica，直到最后一个sync操作后，才处理读操作。想要读取最新数据，需要sync再读。
- 只是保证了一个client的FIFO order（同一个clien的Linearizability），即同一个client的命令可以保证下一次读到的是上一次的写。但是对于不同的client来讲，client2不一定能准确读到刚刚client1写的数据
# 尽管Zookeeper不是Linearizability，但是在别的方面还是有用的
sync()能够让client