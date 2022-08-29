# Multi-Version Concurrency Control

MVCC是比 concurrency control protocol更大的概念，并不是OCC、T/O、2PL之类的东西，是设计和构建数据库系统的一种方式，即通过维护多版本数据来做到并发执⾏事务。

- The DBMS maintains multiple physical versions of a single logical object in the database.
  - When a transaction writes to an object, the DBMS creates a new version of that object.
  - When a transaction reads an object, it reads the newest version that existed when the transaction started.

![](CMU445-19-Multi-Version-Concurrency-Control/20220828105132.png)

---

![](CMU445-19-Multi-Version-Concurrency-Control/20220828113633.png)

T2 R(A)读取A0还是A1取决于隔离级别

T2 W(A)时遇到了write-write confict，假设使用2PL，那么需要等待T1提交后才会继续执行

# Design Decisions

## Concurrency Control Protocol

遇上write-write conflict时需要使用其中一种协议：Timestamp Ordering、Optimistic Concurrency Control、Two-Phase Locking

## Version Storage

- This how the DBMS will store the different physical versions of a logical object.

- The DBMS uses the tuple’s pointer field to create a **version chain** per logical tuple. 类似链表 
  - This allows the DBMS to find the version that is visible to a particular transaction at runtime.
  - Indexes always point to the head of the chain. 
  - A thread traverses chain until you find the version that is visible to you. 
  - Different storage schemes determine where/what to store for each version.

### Append-Only Storage

![](CMU445-19-Multi-Version-Concurrency-Control/20220829094243.png)

可以按照从新到旧或者从旧到新排序

### Time-Travel Storage

main table保存每个tuple的最新版本

![](CMU445-19-Multi-Version-Concurrency-Control/20220829140257.png)

### Delta Storage

更新时只复制这次更新的值，不需要保存整个tuple。下面的例子是只有一个属性value

![](CMU445-19-Multi-Version-Concurrency-Control/20220829141148.png)

