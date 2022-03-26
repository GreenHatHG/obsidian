# 为什么要阅读这篇论文
- cache coherence
- distributed transactions
- distributed crash recovery
- 三者的相互作用
# 整体的设计
- a network file system，与现有的应用程序共同工作，类似普通的unix程序。
![[Pasted image 20220326232624.png]]
可以将petal想象成一个磁盘，通过网络将数据共享给Frangipani，看起来就像从普通磁盘上读取数据

