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
