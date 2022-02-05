http://nil.csail.mit.edu/6.824/2020/notes/l-raft2.txt
# topic: persistence (Lab 2C)
## server crash后应该怎么办
1. 使用empty server代替
	- 需要将整个日志或者snapshot传输到new server
	- 虽然很慢，但是也要实现，避免crash是永久的
2. 重启server并重新恢复状态 
	- 需要持久化状态，避免多台机器同时断电
## server reboot后恢复正常需要持久化什么
- Figure 2：`log[]`, currentTerm, votedFor
- votedFor：避免投票后重启在同一term内又投票给另外一个candidate
- currentTerm：确保term是递增的，并且用来检测leader和candidate的RPC请求
- 何时保存：状态发生后或者在发送RPC和接收RPC前
## 为什么不需要保存这些状态

## 持久化通常是性能的瓶颈
- hard disk write: 10ms, SSD write: 0.1ms, 所以限制100~10000 ops/second
- 潜在的瓶颈：RPC（<< 1ms on LAN）[Much less than](https://math.stackexchange.com/questions/1516976/much-less-than-what-does-that-mean)
- 解决方法：批量写入、写入battery-backed RAM而不是disk
## server crash+reboot后怎么恢复正常
- 简单方法：re-play整个持久化日志
- faster：使用snapshot并仅恢复