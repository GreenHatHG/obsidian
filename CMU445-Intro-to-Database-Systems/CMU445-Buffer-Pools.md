# Buffer Pools

How the DBMS manages its memory and move data back-and-forth from disk.

- Spatial Control
  - Where to write pages on disk
  - 目标：使经常一起使用的page在磁盘上尽可能物理靠近。
- Temporal Control
  - When to read pages into memory, and when to write them to disk.
  - The goal is minimize the number of stalls(*停顿*) from having to  read data from disk.

## Buffer Pool Organization

![png](CMU445-Buffer-Pools/05-bufferpool_12.JPG)

### Meta Data

Meta-data maintained by the buffer pool:

#### Page Table

In-memory **hash table** that keeps track of pages that are currently in memory. It maps **page ids** to **frame locations** in the buffer pool.

![png](CMU445-Buffer-Pools/05-bufferpool_17.JPG)

Pin page3 & Latch Page2

`Page Table` vs `Page Directory`:

- The `page directory` is the mapping from page ids to page locations in the database files.
  - All changes must be recorded on disk to allow the DBMS to find on restart.
- The `page table` is the mapping from page ids to a  copy of the page in buffer pool frames.
  - This is an in-memory data structure that does not need to be stored on disk.

#### Dirty Flag

Threads set this flag when it modifies a page. This indicates to storage manager that the page must be written back to disk.

#### Pin Counter

- This tracks the number of threads that are currently accessing that page (either reading or modifying it). A thread has to increment the counter before they access the page.
- If a page’s count is greater than zero, then the storage manager is not allowed to evict(*驱逐*) that page from memory.

### Optimizations

#### Multiple Buffer Pools

- The DBMS does not always have a single buffer  pool for the entire system.
  - Multiple buffer pool instances
  - Per-database buffer pool(*每个数据库一个*)
  - Per-page type buffer pool
- Helps reduce latch contention and improve locality(局部优化策略).

- 如何根据record id定位到buffer pool
  - `Object Id`: 扩展record id，添加object id，维护id到buffer pool的映射。
  ![png](CMU445-Buffer-Pools/05-bufferpool%20(2)_22.JPG)
  - `Hashing`: 对record id进行hash，通过Hash(x)确定在pool中的哪个位置，通过`Hash(x)%n`(num buffer pool)确定在哪个buffer pool。
  ![png](CMU445-Buffer-Pools/05-bufferpool%20(2)_23.JPG)

#### Pre-Fetching

The DBMS can also prefetch pages based on a query plan.

即减少从磁盘读取产生的停顿，额外加载多一点数据到内存。mmap本身就支持prefetch功能，但是只在Sequential Scans的情况下才生效，因为读取是顺序的，正好操作系统也把要读的下一page提前加载到了内存。

如下，读取到page1的时候，page1没有在内存，把page1加载到内存的时候，顺便把page2，3也加载进内存

![png](CMU445-Buffer-Pools/20220527123642.png)

但是遇到Index Scans就不生效了，因为读取可能是跳跃的。index-page: 0->1->3->5。所以得数据库系统自己处理内存那一块，并不能直接完全用系统的虚拟内存。

![png](CMU445-Buffer-Pools/20220527124354.png)

#### Scan Sharing

