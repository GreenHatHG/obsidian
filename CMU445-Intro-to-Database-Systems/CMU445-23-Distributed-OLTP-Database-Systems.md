If the other nodes in a distributed DBMS cannot be trusted, then the DBMS needs to use a byzantine fault tolerant protocol (e.g., blockchain) for transactions.

# Atomic Commit Protocols

某个节点知道该如何与其他节点进⾏通信，现在提交事务是否安全

- Two-Phase Commit (Common) 可能是最流行的，paxos的退化版本
- Three-Phase Commit (Uncommon) 
- Four phase (Uncommon)  微软提出，FaRM分布式数据库中使用，因为使用到了RDMA（远程内存访问）
- Paxos (Common)
- Raft (Common)
- ZAB (Apache Zookeeper)
- Viewstamped Replication (first probably correct protocol)

2PL提交中的coordinator和Paxos的vote其实是一回事，只是2PL提交要让所有⼈同意才能提交事务，Paxos只需要大多数同意就可以提交事务。

# Replication

⼤多数⼈不需要某种partitioned distributed DBMS来处理workload，使用replication的方式就足够了

## Number of Primary Nodes

根据primary node的数量有两种选择

### Primary-Replica

- All updates go to a designated(*指定的*) primary for each object. 
- The primary propagates(*传播*) updates to its replicas without an atomic commit protocol, coordinating all updates that come to it. (*处理所有的update*)
- Read-only transactions may be allowed to access replicas if the most up-to-date information is not needed. 
- If the primary goes down, then hold an election to select a new primary.

### Multi-Primary

Transactions can update data objects at any replica. Replicas must synchronize with each other using an atomic commit protocol like Paxos or 2PC.

![22-distributedoltp_75](CMU445-23-Distributed-OLTP-Database-Systems/22-distributedoltp_75.JPG)