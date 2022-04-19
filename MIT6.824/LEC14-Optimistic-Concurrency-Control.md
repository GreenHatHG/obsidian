# why are we reading about FaRM
- transactions+replication+sharding
- RDMA NIC巨大的性能潜力
# FaRM对比Spanner
- 两者共同：replicate、2PC
- Spanner：
  1. 已经完善且部署的系统
  2. 专注于跨DC复制同时处理不同地方的数据的事务能力高效
  3. 只读事务TrueTime
  4. r/w事务需要10~100ms
  5. 主要瓶颈：卫星信号传播上的延迟、DC之间的网络延迟
- FaRM：
	1. 研究型，探索RDMA
	2. 所有replica都在同一个DC
	3. RDMA限制了系统的设计：必须使用Optimistic Concurrency Control (OCC)
	4. 简单事务只需要58microseconds，比Spanner快100倍
	5. 主要瓶颈：服务器上的CPU时间
# 整体设计
- Zookeeper+configuration manager，决定哪个是primary哪个是backup
- 每个数据分片对应着primary/backup replication
```
P1 B1
P2 B2
...
```
只要每个分片有一个可用的replica，系统就依旧可用， f+1 replicas tolerate f failures
