# 为什么学习CRAQ
- Chain Replication(CR)，一种与Raft非常不一样的方法。
- CRAQ能够从replica读取数据并且保持强一致性
# 什么是CR
- write：
![[Pasted image 20220310073110.png]]
1. client发送写请求给head server
2. 请求按顺序沿着链下发
3. 每个server用新数据覆盖旧数据
4. 当tail server处理完成后回复给client
- read：
![[Pasted image 20220310073341.png]]
1. client发送读请求给tail server
2. tail server回复给client（不涉及其他server）
- 为了让tail回复，这条链的每个节点必须处理写请求，即整个路径上的节点都已经处理了写请求。
- 如果head server fail，下一个节点可以代替head继续工作（tail server同理，不过是上一个节点）。如果head中途crash，但是数据还没有到tail server，所以就不会回复给client。
- 如果中间的server fail，需要移除该节点，上一个节点重新发送请求给新的下一个节点。
- 不能处理network partition或者spilt brain的情况，需要配合第三方组件configuration manager (cm)来判断哪些服务器或者还是挂掉了，当有问题的时候，cm会重新发出配置决定谁是head，谁是tail，怎么安排链等。cm一般会使用Raft或者Zookeeper。
- 可能不止一条链，也许是replication group，以此来请求分流，这个都由cm去决定。
- 每个节点不需要更新其他服务器是否处于在线情况，当下一个节点挂掉后，上一个节点会一直尝试和下一个节点通信，除非收到了新的配置。
# 为什么CR比Raft更有吸引力
- client请求的接收和回复在CR中是在两个不同的server中处理，Raft需要leader都处理。
- 在CR中head server只需要发送一次请求，Raft需要leader将请求发送给所有的follower。
- 读取数据在CR中是由tail server完成，而在Raft中则是leader，会增加leader的负载。
- 失败的情况比Raft更简单
# 可以让client读取CR中任一replica？
- 当大量读取操作导致tail server负载很高的情况，此时中间的server可能还有很多闲置的性能。因此，如果中间节点也参与进处理读请求的话性能可能会更好。
- paper中提出一种解决方案：
```
Chain1: S1 S2 S3
Chain2: S2 S3 S1
Chain3: S3 S1 S2
```
这不一定有效，如果请求没有均匀分配的话
- 这也会导致强一致性失效，可能会读到未提交的值，或者是从一个replica读到旧值，从另外一个replica读到新值。
# 如何让CRAQ支持强一致性读取任一replica
![[Pasted image 20220311090029.png]]
- 每个replica存储每一个object的version list：clean version和最近写入的dirty version
- write：
	- client向head server发送写请求
	- 写请求在链传递的时候中间每个replica创建新的dirty version
	- tail server则创建clean version，沿着链返回ack，将dirty version转变为clean version
- read from replica：
	- 如果最新版本是clean version，则返回给client
	- 如果最新是dirty version，不能返回recent clean version，因为client可能从别的replica获得了部分新的数据；也不能直接返回dirty version，因为这个可能是未committed的
	- 只需要向tail server查询最新的版本即可（version query）
# 为什么CRAQ支持强一致性读取replica，而Raft/Zookpeer不能
- CRAQ的结构是一条链，所以对于所有的节点：
	- 在写入commit之前，所有节点都知道了这个写入
	- 能够知道何时查询tail server以得到最新的数据
- Raft/Zookpeer的leader不能做到：
	- 
# 这是否意味CR比Raft &c更强大
不是
- 所有的CRAQ replica都处理了请求后才能提交数据，Raft只需要majority
- 如果一个节点变得很慢的话，会影响这个链的性能，Raft则没有这些影响。
- 不能像Raft或者Zookeeper那样立即可以fault-tolerant
