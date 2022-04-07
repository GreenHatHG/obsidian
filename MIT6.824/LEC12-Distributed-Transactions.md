# 话题
 distributed transactions = concurrency control + atomic commit
  - 大量的数据分布在多个服务器上面，操作通常涉及到多次读取和写入
  - 想对代码编写者隐藏分布式的复杂性
# 事务示例
- x=10、y=10是银行数据库中两个账户的余额，x和y在不同的服务器上（可能是不同的银行）
- T1、T2都是事务，T1代表x转1元给y，T2代表审计钱的总额有没有对
![[Pasted image 20220403085535.png]]
# 事务的正确性
通常被称为ACID
- Atomic（原子性）：在遇上故障的情况下，要么全部执行要么全部不执行
- Consistent（一致性）：数据库通常会让应用程序声明一些不变量（比如上面的x和y账户资金总和）
- Isolated（隔离性）：事务之间不能相互影响（比如看到另外一个事务正在修改的值），也称serializable
- Durable（持久化）：committed write是持久的
# serializable
- 对于上面的例子，执行事务的顺序可能是T1、T2或者T2、T1，这两个结果分别是
	```
	T1、T2 : x=11 y=9 "11,9" 
	T2、T1 : x=11 y=9 "10,10"
	```
	这两个执行顺序都是serializable的（存在一种串行执行的顺序，事务并发执行产生的结果得是串行执行的结果集内）
- 如果T1的操作在T2两个get()之间运行，则T2结果是`"10,9"
	![[Pasted image 20220404084213.png]]
	T2在T1两个add()之间执行，T2结果是`"11,10"`
	并发执行事务产生的结果可能会正常，但是上面两种执行顺序都是不合法，因为结果不在合法的范围内（"11,9"和"10,10"）
- serializable模型简单，编写复杂事务时候能够正确去执行事务；如果事务执行的时候修改的是不同的数据对象，那么在该模型下会真正的并行执行事务，使用数据分片不同数据在不同的服务器上面运行
# abort事务
事务在执行一半时候可能会中止，这种叫abort，会取消任何记录的修改
- 事务可能会自动abort，比如查询到账户不存在，或者余额小于0
- 系统可能会强制abort，例如事务执行的时候遇到死锁，需要abort一些事务破坏死锁
- 服务器故障导致abort
# 并发控制-Isolated
- pessimistic（悲观锁）：使用前锁定数据、锁冲突导致延迟
- optimistic（乐观锁）：不加锁修改数据，commit的时候检查写/读是否满足serializable，不满足则重试，称为Optimistic Concurrency Control (OCC)
- 冲突频繁，悲观锁会更快，反之乐观锁
# 悲观锁
- Two-phase locking(2PL)是实现serializable的一种方式
	- 在对任何数据进行读取或者写入之前，必须先去获取该数据对应的锁
	- 直到事务被commit或者abort后，才能释放掉所获得的锁
	- 如果修改完数据就释放锁（没有等事务完全执行完成），除了会出现并发情况下值不同步的问题外，还可能出现幻读现象：T1执行add(x,1)后释放锁，T2就可能获得锁并打印出x的值然后释放锁，接着T1获得锁，但是abort了，因为可能不存在y这个账户，add(y,-1)失败了，这时候因为原子性就会回滚，x的值就不会+1，所以T2会看到一个不应该存在的值。
- 2PL可能会产生死锁，需要添加机制去解决这个（检测或者是锁定超时）
	```
	T1      T2
  get(x)  get(y)
  get(y)  get(x)
	```
	如果锁是行锁的话，T1先获得x的锁，T2接着或者y的锁，然后T1继续执行想要获得y的锁得等待T2执行完成，T2继续执行想要获得x的锁得等待T1执行完成。
# 分布式事务如何应对故障
假设上面的例子中x和y都位于不同的服务器
x已经+1，但刚好执行y的时候就崩溃了
x已经+1，但是轮到y的时候发现账户不存在
想要解决上面的问题就得实现原子性，要么全部执行要么全部不执行，挑战在于如何实现以及对性能的影响。
## two-phase commit protocol(2PC)
- 用于分布式数据库处理多服务器事务
- 数据分片（shard）存在于多个服务器上面，事务在transaction coordinator(tc)上运行
- 每次读/写，TC都会发送RPC到相关的分片服务器（shard server）。shard server称为participant，每个分片服务器管理着对应数据的锁
- 可能会有很多并发事务，很多TC。TC为每个事务分配一个唯一事务ID(TID)，每个RPC消息、table entry都有TID。
  ![[Pasted image 20220404155519.png]]
1. client给TC发送执行事务请求，并等待响应
2. TC给A发送get请求，给B发送put请求，并收到各自的回复（锁住数据后暂时修改，commit后才会持久化）
3. TC给A个B发送prepare消息，A和B会去检查是否能够完成这个事务中的操作，TC会等待每个事务参与者的回复（Yes/No）
4. 如果A和B都回复Yes，则TC向A和B发送commit消息。
5. 收到TC的commit消息后，A/B commit并释放事务对数据的锁，A/B回复ACK消息
6. TC回复给client
- 如果A或B回复No（缺了一条记录或者发生了故障等），则TC发送abort消息，回滚数据
- 每个participant都有一张lock表，将锁与该事务所操作的数据对象关联起来。
## B crash并reboot
- B在crash之前已经给TC发送了Yes，假设此时A也回复了Yes，TC给A和B发送commit消息，那么A可能已经收到并commit了。所以B在收到prepara消息回复Yes之前，需要将所作的修改（生成的新值、lock列表）持久化到磁盘，即使在重启后，也能够commit或者不commit。
- B重启后发现有已经回复Yes，但是未commit的事务日志，B应该询问TC或者等待TC重新发送消息（B此时还持有着事务的锁）
## TC crash并reboot
- TC发送任何commit/abort之前，TC必须将该事务信息写入它的日志中，并持久化。
- 重启后查看日志继续发commit/abort消息，或者participant因没有收到commit消息主动询问
- participant必须根据TID过滤到重复的TC commit消息（可能TC在发送后就崩溃了，重启后又发送一次）
## TC一直没有收到B的Yes/No
- 也许B崩溃了，没有恢复或者正在恢复，或者网络出问题了
- TC会每隔一段时间重试发送prepare消息，但是如果一直没有恢复，TC可以超时并中止（还没有发送任何commit消息）
## B等待prepare时候超时/崩溃
- B还没有回应prepare，TC不能commit
- B单方面中止，并释放锁，对未来的prepare回复No
## B一直没有收到commit/abort--block
- B不可以单方面中止事务，TC可能收到了Yes，并将commit发送给A，A提交并释放锁。此时B得一直等待下去，得让人对TC进行修复重启，然后读取上面保存的日志。
- B不能单方面提交，可能A发送了No
## 简单性
commit/abort均由TC发出，participant之间不用交流，使用2PL相对简单，但是代价是participant发送完Yes之后需要等待TC的响应（可能会被阻塞住）。
## 什么时候可以忘记已提交的事务
- TC必须将事务的有关信息保存在它的日志中，当TC收到ACK后，TC就可以删除该事务的所有信息。
- 当participant收到了commit/abort，并且已经执行完了它们所负责的那部分事务（落地，释放锁），发送ACK给TC后就可以删除该事务的相关信息。因为重试发送的commit/abort，但此时已经没有了事务的相关信息，participant直接回复ACK即可。
## 总结
- 2PL主要用于分片数据库/存储系统上，需要支持可以读取或写入多条记录的具有ACID特性的事务。由很多更专业的存储系统不允许在多条记录上使用事务，那么就不需要2PL了。
- 速度慢：
	- 存在很多网络通信，以至于让participant的事务执行完成。
	- 大量的写入磁盘操作，在participant收到prepare消息回复Yes之前，需要将数据写入磁盘（假如使用机械硬盘，追加数据需要10ms，意味着1s只能处理100个事务）。TC发送commit/abort之前也得写入日志到磁盘。
	- participant还持有锁，如果TC crash了，block的时间会加长。
- 通常只在小数据量的地方使用，不会是银行、航空公司等。
## 对比Raft
- 使用Raft通过replicate获得高可用性，某些server崩溃的时候还能正常运行，每个server都做同样的事情。但是不能保证每个server都去执行某个操作，只能是majority。
- 2PL跟高可用没关系，如果出现了故障还需要等待恢复（TC崩溃需要恢复后读取日志发送commit，participant崩溃会中止事务或者询问TC）。但是每个participant干的事情不一样。
## 结合Raft
即具备Raft的高可用性，也拥有2PL让让participant去执行自己所负责事务的能力。
![[Pasted image 20220407224456.png]]
- 设置三台Raft replicated TC，只需要等待majority对leader进行回复即可
- 每个participant同理