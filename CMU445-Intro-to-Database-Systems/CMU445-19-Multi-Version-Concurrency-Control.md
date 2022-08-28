# Multi-Version Concurrency Control

MVCC是比 concurrency control protocol更大的概念，并不是OCC、T/O、2PL之类的东西，是设计和构建数据库系统的一种方式，即通过维护多版本数据来做到并发执⾏事务。

- The DBMS maintains multiple physical versions of a single logical object in the database.
  - When a transaction writes to an object, the DBMS creates a new version of that object.
  - When a transaction reads an object, it reads the newest version that existed when the transaction started.

![](CMU445-19-Multi-Version-Concurrency-Control/20220828105132.png)



T2 R(A)读取A0还是A1取决于隔离级别

T2 W(A)时遇到了write-write confict，假设使用2PL，那么需要等待T1提交后才会继续执行

![](CMU445-19-Multi-Version-Concurrency-Control/20220828113633.png)

