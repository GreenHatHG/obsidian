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
- 需要通过网络发送大量数据--log和dirty data pages，即使只是几bytes的更改，data pages也很大
- 为了性能，两个replica在同一个数据库中心，整个数据中心挂了则数据库都挂了
