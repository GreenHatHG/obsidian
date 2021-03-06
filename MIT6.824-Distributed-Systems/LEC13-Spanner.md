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
- 每个replica保存数据的时候，会保存该数据的多个时间戳版本，只读事务根据时间戳读取数据，获取时间戳最高的那个版本，但是这个时间戳要比只读事务的时间戳小
有三个正在执行的事务
![[Pasted image 20220412085238.png]]
`@ 10`代表某个时间戳，`x@10=9`代表写入一个数据时间戳副本
T3读取x的值的时候带上`@15`，读取到`x=9`，读取y的值时候，T2已经commit，但是因为读取的数据的时间戳得小于`@15`，所以读取到`y=11`
上述的结果是serializable: T1、T2、T3，按照时间戳顺序。
## safe time解决replica不在majority
在@15读取之前，replica查看最新的一条日志的时间（代表replica所知道leader的最新的时间），如果最新的时间没有>15（代表着replica已经知道了前15时间内发生的事情），那么replica就会延迟回复给client。
# 时间不同步会出现什么问题
- r/w事务不会受到影响，因为没有用到SI
- r/o事务读取的时间比实际时间大：读取将阻塞，需要等待Paxos leader追赶到最新时间之后，所以事务会返回超时，但是正确性没有收到影响。
- 比实际时间小：将会错过很多近期的提交修改，返回旧版本的数据，违反了Externally consistent
  ![[Pasted image 20220417113912.png]]
  T2读取@0提交的版本，即x=1，但是这里应该读取到x=2
# 时间同步
每个DC中的计算机都能有相同的时间吗，实际上是不能的。时间由政府制定，并通过各种协议分发，比如GPS（通过GPS卫星发送到DC中的GPS接收器）、NTP
![[Pasted image 20220417115849.png]]
主要问题是不知道DC离GPS发送器有多远，通过网络获取时间存在延迟。
## TrueTime
server询问Time service会返回一个TTinterval区间`[earliest, latest]`，保障正确的时间位于区间内的某个点。
两个规则保障Externally consistent（确保r/w T1在r/o T2开始之前完成，即TS1<TS2）
- start rule：一个事务选择的时间戳(TS)=`TT.now().lastest`（TT: TrueTime）
- commit wait：只适用于r/w事务，在commit之前，保障TS<TS.now().earliest
场景：T1 commit，然后T2启动，T2必须看到T1的写入
![[Pasted image 20220417153441.png]]
prepare：选择时间戳，并在这之后提交
1. p阶段从TT处拿到的时间是`[1,10]`，所以T1的TS是`@10`
2. 为了保障TS.now().earliest>TS，T1会一直询问时间，在某个时间点，T1获取到新的时间`[11,20]`，此时可以提交了。P点到C点为T1的commit wait范围。
3. T1提交后，T2启动，向TT拿到时间`[10,12]`，T2的TS是`@12`，所以T2会拿`@10`对应的时间戳版本数据，根据safe time机制T2知道T1最新时间超过`@10`了，所以能拿到T1写入的值。
实际上，commit wait保证了r/w事务完成后开始的r/o事务有更高的时间戳，从而可以看到r/w事务的写入。