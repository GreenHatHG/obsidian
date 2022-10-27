#  System Architectures

![21-distributed_11](CMU445-22-Introduction-to-Distributed-Databases/21-distributed_11.JPG)

A single-node DBMS uses what is called a **shared everything** architecture. 

This single node executes workers on a local CPU(s) with its own local memory address space and disk. 

## Shared Memory

- An alternative to shared everything architecture in distributed systems is shared memory. 

- CPUs have access to common memory address space via a fast interconnect. CPUs also share the same disk.

- In practice, most DBMSs do not use this architecture, as it is provided at the OS / kernel level. It also causes problems, since each process’s scope of memory is the same memory address space, which can be modified by multiple processes.

- Each processor has a global view of all the in-memory data structures. Each DBMS instance on a processor has to “know” about the other instances.

## Shared Disk

- In a shared disk architecture, all CPUs can read and write to a single logical disk directly via an interconnect, but each have their own private memories. This approach is more common in cloud-based DBMSs.
- DBMS的执行层可以独立于存储层进行扩展。添加新的存储节点或执行节点不会影响其他层中数据的布局或位置。
- Nodes must send messages between them to learn about other node’s current state. That is, since memory is local, if data is modified, changes must be communicated to other CPUs.
- Nodes have their own buffer pool and are considered stateless. A node crash does not affect the state of the database since that is stored separately on the shared disk. The storage layer persists the state in the case of crashes.

![](CMU445-22-Introduction-to-Distributed-Databases/20221027094845.png)

## Shared Nothing

大部分人会考虑这种架构

- In a shared nothing environment, each node has its own CPU, memory, and disk. Nodes only communicate with each other via network.
- It is more difficult to increase capacity in this architecture because the DBMS has to physically move data to new nodes. 
- It is also difficult to ensure consistency across all nodes in the DBMS, since the nodes must coordinate with each other on the state of transactions. 
- The advantage, however, is that shared nothing DBMSs can potentially(*潜在的*) achieve better performance and are more efficient then other types of distributed DBMS architectures.

每个节点上都拥有该数据库中的⼀部分数据，标注了该节点所拥有的数据范围

![](CMU445-22-Introduction-to-Distributed-Databases/20221027101551.png)

垂直扩展机器成本更高，并且得到收益也会递减，一台机器的硬盘内存cpu存在着上限。

