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
1. Spanner client生成一个唯一的事务ID（TID）给所有消息打上标记。向数据分片x所属的Paxos group中的leader发送读请求，需要首先获取x对应的读锁，y同理。
3. 获取后client会计算x和y的新值是什么
4. 当client要向leader提交的时候，选择一个Paxos group作为TC使用（两个蓝框的y，作为leader和TC）。client发送x的写请求（携带了TC对应的id）给x的leader，leader收到后发送prepare消息给对应的follower，并写到Paxos日志中，收到了majority的回复后，会发送一个Yes给TC
5. TC收到所有的Yes后，TC就会提交这个事务。TC安全落地日志后就会向X和Y对应的leader发送commit消息，leader对Paxos group中的follower发送commit消息


