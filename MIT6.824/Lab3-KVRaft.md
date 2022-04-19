# Lab3

ref: [6.824 Lab 3: Fault-tolerant Key/Value Service (mit.edu)](http://nil.csail.mit.edu/6.824/2020/labs/lab-kvraft.html)

## 介绍

- 使用Lab2实现的Raft库构造一个 fault-tolerant key/value storage service，由多个server组成，只要majority处于正常情况，就应该继续处理client的请求。
- 支持三种操作：`Put(key, value), Append(key, arg), Get(key)`，维护一个简单的k/v数据库，k和v都是字符串类型。Get不存在对应的key返回空字符串，Append一个不存在的key应该像Put操作一样。client通过Clerk方法与server交互，比如`Clerk.Put()`
- 强一致性
- 3A: implement the service，不用担心Raft log过多的情况；3B: implement snapshots (Section 7 in the paper)，允许Raft丢弃old log entries。
- 应该重新阅读论文，特别是Sections 7和8

## 入门

在`src/kvraft`中提供了代码框架和测试，需要修改`kvraft/client.go, kvraft/server.go,kvraft/common.go(如果需要)`

## 3A: Key/value service without log compaction

每个kvserver建立在Raft上，Clerk会将Put、Append、Get RPC发送给leader的kvserver，以便保存log。
Clerk有时候不知道哪个kvserver是leader，如果RPC发送给不是leader的kvserver、无法连接的kvserver、leader kvserver commit log失败，此时需要重试发送给不同的kvserver。

### 3A-task1

实现最基本的kvserver，不用考虑故障和丢失log的情况，通过TestBasic3A

- 需要实现client.go中发送Put/Append/Get RPC方法以及server.go中PutApeend()、Get() RPC handler。
- 将op struct（需要补充下需要的字段）传递给Raft的start()方法以便Raft commit kvserver的Get/Put/Append log。
- 可以向Raft的ApplyMsg、AppendEntriesArgs等结构添加字段

### 3A-task2

在task1基础上添加容错机制、处理重复的Clerk请求（等待RPC回复超时、重新发送给另外一个leader）

- Clerk可能必须多次发送RPC以便找到有响应的kvserver，如果leader故障，那么Clerk可能不会收到回复，因此可能需要将请求重新发送给另外一个leader（已经commit的情况除外）。
- Raft应该只执行一次Clerk.put()、Clerk.Apeend()的请求，所以需要确保重新发送请求的时候不会导致Raft重复执行同一个请求两次。
- 检测leader故障：kvserver检测Raft的term发生了变化。
- Clerk可以记录哪个是kvserver是leader，优先发送请求，加快速度。
- 需要唯一标识client操作，确保kvserver的每个操作只执行一次

## 3B: Key/value service with log compaction

kvserver时不时持久化存储当前状态的快照（snapshot），并且Raft丢弃快照之前的日志。
当服务器重启后（或者follower远远落后于leader）时，服务器首先安装快照，然后从快照之后的点开始执行日志。

- 在Raft和kvserver之间设计个接口，以允许Raft丢弃日志
- 修改Raft代码兼容仅存储部分日志的情况
- 丢弃日志的方式：GC或者重复利用内存
- StartKVServer()有个maxraftstate参数，代表持久化Raft状态最大允许大小（bytes，包括日志，不包括快照）。
- 应该将maxraftstate与persister.RaftStateSize()比较，以便创建快照和丢失日志。如果maxraftstate为-1，则不需要快照。

### 3B-task1

修改代码传递给Raft一个log index，代表丢弃该索引之前的日志，只存储之后的日志。修改后的代码能通过Lab2
