# Raft除了GFS master replication还有什么作用
- fault-tolerant kv database
- MapReduce master fault-tolerant
- fault-toletant locking service
# Raft收到read request是否依旧提交no-op
no-op: no operation
section8提到了这个点，需要两个措施去保障leader的合法性
- leader term开始时候心跳提交no-op来确定commited log
- 处理read request之前通过心跳确定自己是不是已经过期了
