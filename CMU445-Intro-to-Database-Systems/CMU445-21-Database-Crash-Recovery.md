# ARIES

**A**lgorithms for **R**ecovery and **I**solation **E**xploiting **S**emantics (ARIES) is a recovery algorithm developed at IBM research in early 1990s for the DB2 system.

并不是所有系统都像本文中定义的那样实现ARIES，但这些系统的实现都接近ARIES。

There are three key concepts in the ARIES recovery protocol:

- **Write Ahead Logging**: Any change is recorded in log on stable storage before the database change is written to disk (STEAL + NO-FORCE).
- **Repeating History During Redo**: On restart, retrace(*回溯*) actions and restore database to exact(*确切的*) state before crash.
- **Logging Changes During Undo**: Record undo actions to log to ensure action is not repeated in the event of repeated failures.

# WAL Records

Write-ahead log records extend the DBMS’s log record format to include a globally unique *log sequence number* (LSN). 对于一个事务来说，日志序列号不需要是连续的，取决于使用哪种并发控制协议。

系统中的各个组件跟踪属于它们的LSN

![21-recovery_8](CMU445-21-Database-Crash-Recovery/21-recovery_8.JPG)

- Each data page contains
  - **pageLSN**: The LSN of the most recent update to that page.
  - **recLSN**: Oldest update to page since it was last flushed(*自从上次flush以来*).
- The **flushedLSN** in memory is updated every time the DBMS writes out the WAL buffer to disk. 是一个指针，指向某个lastLSN

每次修改数据时候，会先往内存中的log buffer添加记录并且得到该日志的LSN，然后修改page并更新pageLSN（因为拿到了write latch，所以可以直接更新）。每当从buffer pool中移除page的时候始终会去更新flushedLSN，以弄清楚已经往磁盘写入了多少log。

![20-recovery_28](CMU445-21-Database-Crash-Recovery/20-recovery_28.JPG)

假设pageLSN=12，flushedLSN=16，现在想将page flush到磁盘，因为pageLSN<=flushedLSN，代表日志已经落地到磁盘，可以flush到磁盘。

假设pageLSN=19，不能刷出到磁盘，因为对应的日志还没有落地到磁盘。

# Normal Execution

下面的讨论都是基于以下简化的事务特征：

- All log records fit within a **single page**.
- Disk writes are **atomic**.
- Single-versioned tuples with **Strict 2PL**.
- **STEAL + NO-FORCE** buffer management with WAL.

## Transaction Commit

When a transaction goes to commit, the DBMS first writes COMMIT record to log buffer in memory. Then the DBMS flushes all log records up to and including the transaction’s COMMIT record to disk. Note that these log flushes are sequential, synchronous writes to disk. There can be multiple log records per log page.

Once the COMMIT record is safely stored on disk, the DBMS returns an acknowledgment back to the application that the transaction has committed.

 At some later point, the DBMS will write a special **TXN-END** record to log. This indicates that the transaction is completely finished in the system and there will not be anymore log records for it. These TXN-END records are used for internal bookkeeping and do not need to be flushed immediate.

当事务commit记录被持久化到磁盘，可以告诉外界已经成功提交了，但是事务内部并未完全完成，依旧可以去维护一些内部元数据，比如维护bookkeeping代表所有活跃的事务，当添加TXN-END的时候就看不到与该事务相关的任何信息，可以从内部的bookkeeping中移除。

![](CMU445-21-Database-Crash-Recovery/20220906095621.png)