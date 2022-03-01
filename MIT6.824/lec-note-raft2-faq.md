# Raft除了GFS master replication还有什么作用
- fault-tolerant kv database
- MapReduce master fault-tolerant
- fault-toletant locking service
# Raft收到read request是否依旧提交no-op
no-op: no operation
section8提到了这个点，需要两个措施去保障leader的合法性
- leader term开始时候心跳提交no-op来确定commited log
- 处理read request之前通过心跳确定自己是不是已经过期了
# 为什么需要提交no-op

# 使用心跳机制提供lease(只读)操作是如何工作的，为什么要timing for safety
leader发出AE RPC告知100ms之内其是leader，如果得到了majority，那么接下来的100ms leader就可以处理read-only request，而不用进一步与follower通信。
所以就需要每个server的时间保持一致
# InstallSnapshot会产生很大的网络开销吗
会的，如果状态比较多的话（比如数据库），这不是一个容易解决的问题。
- 让leader保留足够的log以覆盖follower常见滞后情况下需要的log或者短暂离线的情况
- 只传输差异的部分，比如数据库最近更改的数据。
#  写入snapshot的时间可能会超过election timeout吗，因为需要大量数据append
对于大型的server来讲可能是会的。
假设要复制1g数据量的数据库，而磁盘的写入速度只为100m/s，那么写入snapshot可能需要花费10s。
在后台写snapshot（即not wait for the write，可能需要通过child process），并且确保创建snapshot的频率不高于10s一次
