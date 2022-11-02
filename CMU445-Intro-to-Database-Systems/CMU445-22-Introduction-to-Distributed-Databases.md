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

计算节点会从shared-disk系统中拉取数据并放入它们的本地内存，以及计算结果

![](CMU445-22-Introduction-to-Distributed-Databases/20221027094845.png)

## Shared Nothing

大部分人会考虑这种架构

- In a shared nothing environment, each node has its own CPU, memory, and disk. Nodes only communicate with each other via network.
- It is more difficult to increase capacity in this architecture because the DBMS has to physically move data to new nodes. 
- It is also difficult to ensure consistency across all nodes in the DBMS, since the nodes must coordinate with each other on the state of transactions. 
- The advantage, however, is that shared nothing DBMSs can potentially(*潜在的*) achieve better performance and are more efficient then other types of distributed DBMS architectures.

每个节点上都拥有该数据库中的⼀部分数据，标注了该节点所拥有的数据范围，会将查询请求发送给数据所在节点进行本地计算并返回结果

![](CMU445-22-Introduction-to-Distributed-Databases/20221027101551.png)

垂直扩展机器成本更高，并且得到收益也会递减，一台机器的硬盘内存cpu存在着上限。

# Design Issues

1. How does the application find data? 

2. How should queries be executed on a distributed data? Should the query be pushed to where the data is located? Or should the data be pooled into a common location to execute the query? 
3. How does the DBMS ensure correctness?
4. Another design decision to make involves(*涉及*) deciding how the nodes will interact(*交互*) in their clusters. 
   - Two options are `homogeneous` and `heterogeneous` nodes, which are both used in modern-day systems. 同构节点异构节点

## Homogeneous Nodes

- Every node in the cluster can perform the same set of tasks (albeit on potentially(*尽管可能在*) different partitions of data), lending itself well to(*从而很好地*) a shared nothing architecture.  可以将查询发送给任意一个节点，该节点会弄清楚所寻找的结果是什么。
- This makes provisioning and failover(*配置和故障转移*) “easier”. Failed tasks are assigned to available nodes.

## Heterogeneous Nodes

给每个节点分配指定的任务，添加节点时候需要知道应该添加的节点是哪种类型的。

Mongodb使用的是这种架构，有一些特殊用途的节点，负责处理系统中特定的任务。当应用程序想要发送一个请求来执行一个查询时，会始终跑到router节点，router节点并不清楚有什么数据，会去查询config server弄清楚数据在哪些分片中。接着router节点将请求发送给shared server，shared server执行查询并返回结果。

![](CMU445-22-Introduction-to-Distributed-Databases/20221102102849.png)



