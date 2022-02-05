http://nil.csail.mit.edu/6.824/2020/notes/l-raft2.txt
# topic: persistence (Lab 2C)
## server crash后应该怎么办
1. 使用empty server代替
	- 需要将整个日志或者snapshot传输到new server
	- 虽然很慢，但是也要实现，避免crash是永久的
2. 重启server并重新恢复状态 
	- 需要持久化状态，避免多台机器同时断电
## server重启后恢复正常需要持久化什么
- Figure 2：`log[]`, currentTerm, votedFor
- votedFor：避免投票后重启在同一term内又投票给另外一个candidate
- currentTerm：确保term是递增的，并且用来检测leader和candidate的RPC请求
- 何时保存：状态发生后或者在发送RPC和接收RPC前