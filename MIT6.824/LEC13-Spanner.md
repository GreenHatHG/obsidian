# 为什么读该论文
- wide-area distributed transactions
- 2PC太慢并且容易阻塞，但是Spanner将2PC用在Paxos之上
- 谷歌内部广泛使用
# 背景
Google F1广告数据库以前采用了许多分片的MySQL和BigTable数据库，维护起来麻烦，而且只能在单个数据库上使用事务，为此需要：
