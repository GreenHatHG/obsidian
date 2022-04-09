# 为什么读该论文
- wide-area distributed transactions
- 2PC容易因为TC崩溃导致所有server阻塞，但是Spanner将2PC用在Paxos之上避免该问题
- 通过同步时间（Synchronized time）来实现高效的只读事务
- 谷歌内部广泛使用 
# 背景
Google F1广告系统中的数据过去是存放在很多不同的MySQL和BigTable数据库，维护这些分片数据库费时费力，而且只能在单个数据库上使用事务，为此需要：将数据分散在在不同数据库上获得ge'b'n'f
