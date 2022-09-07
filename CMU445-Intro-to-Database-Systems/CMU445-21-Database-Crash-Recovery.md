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

## Transaction Abort

- Aborting a transaction is a special case of the ARIES undo operation applied to only one transaction. *undo的一种特殊情况*

- We need to add another field to our log records
  - prevLSN: The previous LSN for the txn. 为了避免通过反复扫描日志来弄清楚需要撤销哪些操作，可以通过prevLSN找到与某个txn相关的所有操作（并没有记录往磁盘中写入了哪些page）
  - This maintains a linked-list for each txn that makes it easy to walk through its records.
  - The DBMS adds CLRs to the log like any other record but they never need to be undone.

在BEGIN语句中，并没有prevLSN，设置为nil

![](CMU445-21-Database-Crash-Recovery/20220907084412.png)

如何记录abort的动作：compensation log record (CLR)，CLR描述了为撤销前一个更新记录的操作而采取的操作。

![](CMU445-21-Database-Crash-Recovery/20220907091552.png)

处理事务的abort操作时会创建一个CLR日志，会和该事务执行的一个更新操作相关联。日志中有一个undoNext字段指向需要撤销的下一条日志，在这里指向的是begin，所以不需要继续撤销了，添加TXN-END即可。

# Checkpointing

The first two blocking checkpoint methods discussed below pause transactions during the checkpoint process. 

This pausing is necessary to ensure that the DBMS does not miss updates to pages during the checkpoint.

Then, a better approach that allows transactions to continue to execute during the checkpoint but requires the DBMS to record additional information to determine what updates it may have missed is presented.

## Blocking Checkpoints

The DBMS halts(*暂停*) the execution of transactions and queries when it takes a checkpoint to ensure that it writes a consistent snapshot of the database to disk.

1. Halt the start of any new transactions.
2. Wait until all active transactions finish executing.
3. Flush dirty pages to disk.

## Slightly Better Blocking Checkpoints

与之前的检查点方案类似，不同之处在于DBMS不需要等待active transactions完成执行。

