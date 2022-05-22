# Database-Storage1

## Disk-Oriented DBMS

- The database is all on **disk**, and the data in the database files is organized into **pages**.

- In order to operate on the data the DBMS needs to bring the data into memory. It does this by having a **buffer pool** that manages the movement back and forth between disk and memory.

- The DBMS also have an **execution engine** that will execute queries.

- The execution engine will ask the buffer pool for a **specific page**, and the buffer pool will take care of(*负责*) bringing that page into memory and giving the execution engine a pointer to the page in memory.

- The buffer pool manager will ensure that the page is there while the execution engine is operating on that memory.

<img src="CMU445-Database-Storage1/03-storage1_16.JPG" width="50%">

### why not use the os

- A high-level design goal of the DBMS is to support databases that exceed(*超过*) the amount of memory available.

- We want the DBMS to be able to process other queries while it is waiting to **get the data from disk**.

- It's like virtual memory. One way to achieve this virtual memory, is by using **mmap** to map the contents of a file in a process address space, which makes the OS responsible for moving pages back and forth between disk and memory.

- If mmap hits a page fault, this will block the process.

- DBMS (almost) always wants to control things itself and **can do a better job at it**.
  - Flushing dirty pages to disk in the correct order
  - Specialized prefetching(*预读数据*)
  - Buffer replacement policy(*策略*)
  - Thread/process scheduling

总的来说，mmap可能会导致性能瓶颈，并且我们需要处理额外的问题。对于DB来讲，我们知道应该将哪个page写入到磁盘或者是加载到内存由此达到最好的调度和性能，但是操作系统对此一概不知，尽管可以利用一些系统提供的函数保证在某个时刻处理我们想要的page。

### File Storage

