# Locks

we need a way to guarantee that all execution schedules are correct (i.e., serializable) without  knowing the entire schedule ahead of time.

Solution: Use `locks` to protect database objects.

## Basic Lock Types

S-Lock、X-Lock

- The DBMS contains a centralized(*集中式*) lock manager that decides decisions whether a transaction can have a lock or not. It has a global view of whats going on inside the system.

- Lock-table: It keeps track of what transactions hold what locks and  what transactions are waiting to acquire any locks.

![17-twophaselocking_17](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_17.JPG)

这里会遇上unrepeatable read的问题，所以需要一个完善的协议去约束，下面的2PL

![17-twophaselocking_18](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_18.JPG)

## 2PL

- Two-Phase locking (2PL) is a pessimistic concurrency control protocol that determines whether a transaction is allowed to access an object in the database on the fly(*动态*). 
- The protocol does not need to know all of the queries that a transaction will execute ahead of time(*提前*).

### Two Phase

- Phase #1: **Growing**
  - Each transaction requests the locks that it needs from the DBMS’s lock manager.
  - The lock manager grants/denies lock requests.
- Phase #2: **Shrinking**
  - The transaction enters this phase immediately after it **releases its first lock**. 可以申请多把锁
  - The transaction is allowed to only release locks that it previously acquired. It cannot acquire new locks in this phase. 这里针对的是一个txn，不是指所有的txn。也就是有的txn处于1阶段，有的可以处于2阶段。

正常的情况是：

![17-twophaselocking_21](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_21.JPG)

异常的情况是这样的：

![17-twophaselocking_22](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_22.JPG)

2PL示例：

![17-twophaselocking_26](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_26.JPG)

### Cascading Aborts

When a transaction aborts and now another transaction must be rolled back, which results in wasted work(*导致无用工*).

这里的情况是T2读到了T1的值，但是T1已经abort了，单独使用2PL不会避免出现了脏读的情况。这里就会出现了依赖，T1 abort，T2也得abort。

![17-twophaselocking_29](CMU445-17-Two-Phase-Locking-Concurrency-Control/17-twophaselocking_29.JPG)

## Strong Strict 2PL



