# 介绍
- 使用Lab2实现的Raft库构造一个 fault-tolerant key/value storage service，由多个server组成，只要majority处于正常情况，就应该继续处理client的请求。
- 支持三种操作：`Put(key, value), Append(key, arg), Get(key)`，维护一个简单的k/v数据库，k和v都是字符串类型。Get不存在对应的key返回空字符串，Append一个不存在的key应该像Put操作一样。client通过Clerk方法与server交互，比如`Clerk.Put()`
- 强一致性
- 3A: implement the service，不用担心Raft log过多的情况；3B: implement snapshots (Section 7 in the paper)，允许Raft丢弃old log entries。
- 应该重新阅读论文，特别是Sections 7和8
# 入门
在`src/kvraft`中提供了代码框架和测试，需要修改`kvraft/client.go, kvraft/server.go,kvraft/common.go(如果需要)`
# 3A: Key/value service without log compaction
每个kvserver建立在Raft上，Clerk会将Put、Append、Get RPC发送给leader的kvserver，以便保存log。
Clerk有时候不知道哪个kvserver是leader，如果RPC发送给不是leader的kvserver、无法连接的kvserver、leader kvserver commit log失败，此时需要重试发送给不同的kvserver。
## task1
实现最基本的kvserver，不用考虑故障和丢失log的情况，通过TestBasic3A
- 需要实现client.go中发送Put/Append/Get RPC方法以及server.go中PutApeend()、Get() RPC handler。
- 将op struct（需要补充下需要的字段）传递给Raft的start()方法以便Raft commit kvserver的Get/Put/Append log。
- 可以向Raft的ApplyMsg、AppendEntriesArgs等结构添加字段
- 
