# 介绍
- 使用Lab2实现的Raft库构造一个 fault-tolerant key/value storage service，由多个server组成，只要majority处于正常情况，就应该继续处理client的请求。
- 支持三种操作：`Put(key, value), Append(key, arg), Get(key)`，维护一个简单的k/v数据库，k和v都是字符串类型。Get不存在对应的key返回空字符串，Append一个不存在的key应该像Put操作一样。