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
