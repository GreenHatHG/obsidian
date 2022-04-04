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
