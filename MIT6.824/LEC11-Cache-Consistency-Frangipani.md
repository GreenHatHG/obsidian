# 为什么要阅读这篇论文
- cache coherence
- distributed transactions
- distributed crash recovery
- 三者的相互作用
# 整体的设计
- a network file system，与现有的应用程序共同工作，类似普通的unix程序。
![[Pasted image 20220326232624.png]]
可以将petal想象成一个磁盘，通过网络将数据共享给Frangipani，看起来就像从普通磁盘上读取数据
# 预期用途
- 一个文件系统，能保存自己的home目录以及共享的项目文件，在任何的workstation（可以理解是个人PC）能拿到自己的home目录以及所需要的所有文件。
- 没有涉及到安全问题，彼此电脑之间互相信任，适用于小群体
# Frangipani的设计
- 强一致性
- caching in each workstation -- write-back
	- 所有对文件的更新最初只是在workstation cache中完成--速度快
	- 包括创建文件、目录、重命名等
- 所以Frangipani程序应该安装在workstation，而且petal不会知道workstation上面的文件以及目录信息，所有的逻辑处理复杂性都放在了Frangipani中
	- 这是一种中心化方案（decentralized scheme）
	- 添加更多workstation能添加更多CPU算力，有一定的扩展性，但是存储系统则会增加存储的负载，可能需要更多存储服务器。
	- 