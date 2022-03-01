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
