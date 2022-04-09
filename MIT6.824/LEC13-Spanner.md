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
	- 每个Paxos group彼此独立，每个Paxos group都有属于自己的leader，各自维护着独立的数据版本
- 可以并行加速处理数据、多个DC容错率高、Spanner  client可以直接读取同一地区的DC数据减少网络开销、Paxos只需要majority，能够容忍速度慢的副本。
# Challenges
- 读取本地副本必须得同步最新的数据，但是Paxos只需要majority，意味着本地副本可能无法同步最新的写入。
- 一个事务可能涉及到多个Paxos group，需要分布式事务和强一致性。
# R/W transaction




