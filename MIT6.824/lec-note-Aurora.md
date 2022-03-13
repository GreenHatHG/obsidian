# 为什么要学习Aurora
- 作为近几年成功的云服务，解决了严重的问题
- 设计良好，有性能的优势
- 使用general-purpose storage架构情况下的局限性
- 许多关于云基础架构中重要的内容
# Amazon EC2，cloud computing，针对于web
![[Pasted image 20220312154755.png]]
- 租用直接运行在Amazon数据中心物理机器上的virtual machines instances
- 使用的存储是连接在物理磁盘上的virtual local disk
- 客户在EC2上面运行着stateless www server或者DB
- 但是EC2不适合DB：扩展功能和容错功能有限（可以通过S3大容量存储服务定期存储数据库的snapshot）
# Amazon EBS (Elastic Block Store)
![[Pasted image 20220312160129.png]]
- 使用的是Chain Replication，基于paxos的configuration manager
- 如果DB EC2崩溃，只需要在另一个EC2上面重新启动一个DB并挂载同一个EBS volume
- EBS不是shared storage，只能由一个EC2挂载
# DB-on-EBS缺点
- 需要通过网络发送大量数据--log和dirty data pages，即使只是几bytes的更改，data pages也很大，可能一个page是8k
- 为了性能，两个replica放在同一个"availability zone" (AZ)--machine room or datacenter，AZ挂了则数据库都挂了
# generic transactional DB
示例：单机，x账户转账10元到y账户，在事务执行期间，x和y将被锁住，直到commit完成后释放，事务完成后数据就被持久化。
```
begin
x = x + 10
y = y - 10
end
```
![[Pasted image 20220313112022.png]]
- WAL(Write-Ahead Log)：让系统实现容错能力的关键部分
1. DB server在事务运行时只会修改cached data page，并将更新信息（log entry）添加到WAL
![[Pasted image 20220313112559.png]]
2. 安全提交WAL到磁盘后，释放x和y的锁，并回复给client
3. 随后将修改后的data page从缓存写入到磁盘，但是数据库一般会积累很多未写入磁盘的值在cache上面。当db crash后重启，会扫描commit记录，执行redo和undo操作。
# Multi-AZ RDS
database-as-a-service，而不是客户自己运行db在EC2
![[Pasted image 20220313120857.png]]
- 目标：通过cross-AZ replication实现更好的容错能力
- 每个写数据必须发送到本地EBS和另外一个EC2上运行的DB，包括log entry和所有的dirty data pages
- 数据库写入必须等待四个EBS完成后才能回复给client，所以数据量大的话这里会有很大的延迟，但是容错性更好。
# Aurora的做法
![[Pasted image 20220313122926.png]]
- 一个DB client给一个客户使用，底层对应着6个replica
- 但是6个replica并不比RDS慢，因为只需要发送log entry（small），而不用发送dirty data pages（big）。但是这里并不是通用的，只能处理MySQL的log entry，EBS则具有通用，因为只是一个磁盘。
- 不需要让6个replica都确认写请求，只要有Quorum（达到法定确认人数，事实证明只需要任意4个，简单的来说，在写操作时候，可以忽略最慢或者基本死掉的replica），数据库服务器就能够继续运行。
- 35x throughput increase，可能主要是因为发送的数据少得多，但是增加了cpu和存储的使用量。
# Aurora's storage fault tolerance goal
- 即使一个AZ完全死了也能处理写请求
- 即使一个AZ完全死了+另外一台server发生故障，也能够处理读请求
- 即使在某些存储服务器变慢或者暂时不可用情况下，服务也能够继续进行
- fast re-replication（快速复制出另外一个replica或者修复dead replica）
