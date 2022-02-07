# 任务
实现Raft的persistence相关
# 提示
- 在Figure2可看到哪些状态应该持久化
- 本次实现不需要用到disk，应该是直接操作Persister对象
	- Raft.make()会提供一个Persister，会持有Raft最近持久化的状态（如果有）
	- 