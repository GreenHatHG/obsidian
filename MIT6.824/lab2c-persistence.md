# 任务
实现Raft的 `save and restore persistenct state`
- 完成raft.go中的`persist()`和`readPersist()`
# 提示
- 在`Figure2`可看到哪些状态应该持久化
- 本次实现不需要用到disk，应该是直接操作`Persister`对象（persister.go）
	- Raft.make()会提供一个Persister，会持有Raft最近持久化的状态（如果有）
	- Raft应该从Persister中获取初始化的状态，并且每次状态改变时候更新persistent state。对应着两个方法`ReadRaftState()`和`SaveRaftState()`
- 需要将状态序列化再传递给persister，使用`labgob encoder`，参考`persist()`和`readPersist()`注释
	- 注意不要使用`lower-case field names`
- 在需要更新persistent state的地方使用`persist()`
- You will probably need the optimization that backs up nextIndex by more than one entry at a time.