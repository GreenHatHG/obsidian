# Why this paper
- wide-area distributed transactions
- 2PC容易因为TC崩溃导致所有server阻塞，但是Spanner将2PC用在Paxos之上避免该问题
- 通过同步时间（Synchronized time）来实现高效的只读事务
- 谷歌内部广泛使用 
# Motivation
- Google F1广告系统中的数据过去是存放在很多不同的MySQL和BigTable数据库，维护这些分片数据库费时费力，而且只能在单个数据库上使用事务
- 为此需要：将数据分散在在不同数据库上获得更好的性能和容错能力并且想要在多个数据分片上使用事务的能力
- 以只读事务为主，强一致性
# Basic organization
![[Pasted image 20220409161743.png]]
1. 假设有三个DC（数据中心），将数据按key为a、b...开头分片存储在一个DC1上，并且DC2、3作为副本。
2. 每个DC都有多个Spanner clinet，比如是web server，例如gmail
3. 副本由一种变体的Paxos（与Raft类似，存在leader）管理
	- 同一数据不同DC的多个副本组成了一个Paxos group。
	- 每个Paxos group彼此独立，每个Paxos group都有属于自己的leader（如图中2个蓝框的服务器），各自维护着独立的数据版本
- 可以并行加速处理数据、多个DC容错率高、Spanner  client可以直接读取同一地区的DC数据减少网络开销、Paxos只需要majority，能够容忍速度慢的副本。
# Challenges
- 读取本地副本必须得同步最新的数据，但是Paxos只需要majority，意味着本地副本可能无法同步最新的写入。
- 一个事务可能涉及到多个Paxos group，需要分布式事务和强一致性。
# R/W transaction
```
BEGIN
    x = x + 1
    y = y - 1
END
```
- Spanner 2PC，使用Paxos group代替单独的一个服务器作为participant和TC。
![[Pasted image 20220409174341.png]]
1. Spanner client生成一个唯一的事务ID（TID）给所有消息打上标记。向数据分片x所属的Paxos group中的leader发送读请求，需要首先获取x对应的读锁（锁记录存在leader中，锁不会复制），y同理。获取后client会计算x和y的新值是什么
2. 当client要向leader提交的时候，选择一个Paxos group作为TC使用（两个蓝框的y，作为leader和TC）。client发送x的写请求（携带了TC对应的id）给x的leader，需要获取对应的写锁
3. leader收到后发送prepare消息给对应的follower（以复制锁和修改后的值），并将该操作写到leader的Paxos日志中
4. leader收到了majority的回复后，会发送一个Yes给TC
5. TC收到所有的Yes后，TC安全落地日志后就会向X和Y对应的leader发送commit消息，并向client返回结果
6. leader对Paxos group中的follower发送commit消息，并记录TC是commit还是abort，完成后释放事务的锁。
- 不管事务有没有被提交，对应的日志都会被复制到副本，即使TC挂了，还会选择新的leader接手工作，这样就解决了2PC的TC持有锁崩溃而导致的阻塞问题。
- r/w需要很长时间，涉及很多通信的消息，如果DC跨国成本更高，但是因为并行，吞吐量高。
# R/O transaction
- 如果我们能提前知道该事务中所有的操作都是读操作的话，Spanner就能使用速度更快，更加精简，并且不用发送那么多消息的方案了（10x latency improvement）：
	- 从本地replicate读取，避免跨DC读取数据，但是replicate数据不一定是最新的
	- 没有锁，没有2PC，没有TC，避免跨DC发送消息给Paxos group leader，不需要等待锁
## Correctness constraints
- Serializable：所有事务的执行依旧是有序的，只读事务必须看到执行前那个事务中所有写操作的执行结果，看不到后续写入的结果。
- Externally consistent：如果T1在T2开始之前完成，则T2必须看到T1的写入，与linearizable类似，排除读取旧数据的可能性。
## 为什么不直接读取最新的值不采用任何措施
假设正在执行三个事务：
![[Pasted image 20220412080214.png]]
如果让T3直接读取最新的值的话，可能不满足正确性。我们希望的结果是T3要么在T1和T2之间执行完成，要么在T2完成后执行。
## Snapshot Isolation(SI)
- Synchronize all computers' clocks
- 为每个事务分配一个时间戳
	- r/w: commit time
    - r/o: start time
- 如果所有的事务都是按照时间戳的顺序执行，那么事务就会得到正确的执行结果。
- 每个replica保存数据的时候，会保存该数据的多个时间戳版本