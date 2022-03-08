# Zookeeper提出了什么问题
1. 能够将coordination作为一种通用服务去提供吗，可以的话，API应该是怎么样的，其他分布式程序应该怎么去使用它？
2. 我们有N个replica server，能从这个N个server中获得N倍性能吗？
# 将Zookeer视为基于Raft的service
![[Pasted image 20220305160645.png]]
只不过ZooKeeper使用的是zab协议，为ZooKeeper专门设计的一种支持崩溃恢复的一致性协议
# 当我们添加更多的server时候，replication arrangement是否变得更快
replica越多，写入的速度就越慢
leader必须将每次写入发送给越来越多的server
# 可以让follower提供只读服务，这样leader压力就小很多
可能会产生log与leader不一致的情况，导致client读取的数据不对，甚至是产生“倒退现象”，client先从up-to-date replica读，再从logging replica读。这个就不可能是Linearizability
Raft和Lab3不会出现这种情况，因为follower不提供只读服务
# Zookeeper怎么处理这个
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
- 只是保证了一个client的FIFO order（同一个clien的Linearizability），即同一个client的命令可以保证下一次读到的是上一次的写。但是对于不同的client来讲，client2不一定能准确读到刚刚client1写的数据
# 尽管Zookeeper不是Linearizability，但是在别的方面还是有用的
- sync()能够让后续不同的client看到之前client写入的值。只有该数据在整个系统中处于写状态，不允许其他client读到。想要读取最新数据，需要sync再读。缺点是增加了leader的处理时间，不这样做的话就不是linearizable
- 场景1 ready file：master在Zookeeper中维护了一个配置文件（描述了分布系统的东西，比如worker ip，master信息等），里面有一堆文件（可以实现原子更新效果），master会去更新配置文件，在更新的过程中worker不能查看配置，只能看到完全更新后的配置。
	- 正常的操作序列，虽然不是完全linearizable（只有写），但是读只能往前读，所以达了类似linearizable的效果，提高了性能：
![[Pasted image 20220306190528.png]]
- 可能会出现的问题：
![[Pasted image 20220306190548.png]]
	读f1的时候，执行了写操作，导致读到的f2不是原来应该读的
	Zookeeper使用watch事件去解决，当调用exists的时候，除了判断file是否存在，还在这个文件上面设置了watch事件（replicate会创建watch table，文件修改之前查看watch table），当这个文件被修改时候replica会在一个相对正确的时间点通知client，即会在读操作执行之前。
![[Pasted image 20220306191450.png]]
	当replicate crash时候，对应的watch table也会没有，client切换到新的replicate读的时候就不会有对应的watch table。但是client会在合适的时间收到replica崩溃的通知。
# 几个影响
- 当leader failed时候leader必须保存client的write order（？
- replicate需要保障client的读取顺序按照zxid顺序
- client必须跟踪它已读取的最高 zxid
# 提高性能的技巧
- client可以让leader发送异步写入，不必等待
- leader可以批处理请求以减少磁盘和网络开销
# Coordination as a service是怎么样的（Zookeeper有什么用）
## VMware-FT's test-and-set server
- 要求：一个replica无法和其他replica通信，则获取t-a-s lock（test-and-set lock），成为sole server。必须是唯一的以避免存在两个primary（如果出现network partition），必须是fault-tolerant。
- Zookeeper提供了工具，可以写出fault-tolerant test-and-set服务
## Config info
通过Zookeeper发布信息给其他服务使用，比如可以将一组worker中作为当前master的那个ip存放在Zookeeper
## Mater elect
在test-and-set server中有体现，master可以把state存放在Zookeeper，如果master crash，选出一个新的maser代替它，新的master可以从Zookeeper中读取旧master的状态。
## MapReduce
worker可以注册到Zookeeper中，master会在里面记录着worker的任务，worker会从Zookeeper中将任务一件件拿出来，完成后就会移除掉。
# Zookeeper API
- a file-system-like tree of znodes
![[Pasted image 20220308074546.png]]
示例：将一组机器和哪个机器是primary的信息存放在znodes
- znode的分类：regular、ephemeral、sequential（file name + seqno）
