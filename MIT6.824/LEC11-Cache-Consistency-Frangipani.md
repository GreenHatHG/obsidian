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
	- 比如ws1(workstation user 1)想要创建并读写`/grades`：Frangipani会从Petal读取`/infomation`的信息并保存到cache，然后添加`/grades`到cache，但是并不会立马将修改同步到Petal，因为ws1也许会继续修改`/grades`
- 所以Frangipani程序应该安装在workstation，而且petal不会知道workstation上面的文件以及目录信息，所有的逻辑处理复杂性都放在了Frangipani中
	- 这是一种中心化方案（decentralized scheme）
	- 添加更多workstation能添加更多CPU算力，有一定的扩展性，但是存储系统则会增加存储的负载，可能需要更多存储服务器。
# 挑战
- 主要来自caching、decentralized
- cache coherence：ws1创建`/A`，ws2希望能看到`/A`（本地cache不会立即同步到Petal）
- atomicity：两个不同的workstation对同一个目录修改，比如ws1创建`/A`，ws2创建`/B`，最终`/`应该有两个目录，不应该出现覆盖的情况。
- crash recovery：当一个workstation crash，不应该影响到其他用户，即使浏览crashed workstation目录下的文件，也应该看到正确的内容（没有损坏的，不一定要最新）
- Petal里面内置了一套完全独立的容错系统（很像之前讨论的Chain Replication），不在讨论的范围内。
# cache coherence
- 目标是linearizability和caching，即同时兼备性能和一致性
- 许多系统使用了cache coherence protocols：多核处理器、file servers、distributed shared memory，但是Frangipani使用的不是这种，而是使用锁实现。
## Frangipani's coherence protocol
- lock server (LS), with one lock per file/directory，简化版，实际上Frangipani的锁更复杂，允许一个writer或者多个reader对文件操作
```
file  owner
-----------
x     WS1
y     WS1
```
- workstation (WS) Frangipani **cache**：每个workstation会去跟踪它持有的锁
```
file/dir  lock  content(文件或者目录的实际内容)
-----------------------
x         busy  ...
y         idle  ...
```
锁的种类：
1. busy：正在使用数据
2. idle：持有锁，但是现在不使用cached data（结束系统调用后由busy变成idle，比如创建文件、重命名、写入读取）
- workstation使用锁的规则，保证缓存一致性
	- 只有持有该文件锁的时候，才能对这个文件的数据缓存
	- 先获得锁，然后从Petal中读取数据，并保存到缓存
	- 先将修改后的数据写回到Petal，再释放锁
- coherence protocol messages
	- request  (WS -> LS)
	- grant (LS -> WS)
	- revoke (LS -> WS)：请求ws释放idle锁，一般情况下workstation创建了文件立即释放掉，而是由busy变成idle，因为绝大部分情况下，创建了文件还会对其操作。当ws收到revoke且能释放的时候（也就是ws此时没有对文件进行操作），如果缓存数据修改过，则需要按照第3条规则写回到Petal。
	- release (WS -> LS)
## 示例：WS1更改文件z，然后WS2读取z
![[Pasted image 20220328083733.png]]
1. WS1向LS请求文件z的锁
2. 拿到锁
3. 从Petal读取文件z的内容，保存到cache
4. WS2向LS请求文件z的锁
5. 