# 为什么读该论文
- wide-area distributed transactions
- 2PC容易因为TC崩溃导致所有server阻塞，但是Spanner将2PC用在Paxos之上避免该问题
- 通过同步时间（Synchronized time）来实现高效的只读事务
- 谷歌内部广泛使用 
# 背景
- Google F1广告系统中的数据过去是存放在很多不同的MySQL和BigTable数据库，维护这些分片数据库费时费力，而且只能在单个数据库上使用事务
- 为此需要：将数据分散在在不同数据库上获得更好的性能和容错能力并且想要在多个数据分片上使用事务的能力
- 以只读事务为主，强一致性
# 物理机器布局
1. 假设有三个DC（数据中心），将数据按key为a、b...开头分片存储在一个DC1上，并且DC2、3作为副本。
2. 每个DC都有多个Spanner clinet，比如是web server，例如gmail
3. 副本由一种变体的Paxos（与Raft类似，存在leader）管理
	- 同一数据不同DC的多个副本组成了一个Paxos group。
	- 每个Paxos group彼此独立，每个Paxos group都有属于自己的leader，各自维护着独立的数据版本
	- 这样可以并行加速处理数据




