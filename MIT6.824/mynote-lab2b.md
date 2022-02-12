# nextIndex
- 官方描述：for each server, index of the next log entry  to send to that server (initialized to leader last log index + 1)
- `nextIndex[i]`代表着对第i个follower发起Append Entries RPC时**尝试**replicated log的位置，仅仅是猜测并不是真实的，并且出现`log inconsistency`会将该值回退。
- leader收到Append Entries RPC回复后只有是因为`log inconsistency`才能更新nextIndex
- 
# commitIndex
- 官方描述：for each server, index of highest log entry known to be replicated on server  (initialized to 0, increases monotonically)
- commitIndex并不是只有leader才有的，所有server的commitIndex应该是一致的。
-  If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
	- leader发送带有log的Append Entries RPC给follower，append log的follower达到majority后，leader commit该log，并更新commitIndex
	- 第二次发送RPC时候，因为leaderCommit大于follower的commitIndex，代表着leader已经commit了新的log，所以follower根据上述规则更新自己的commitIndex
	- 根据commitIndex > lastApplied，就会apply `[lastApplied+1, commitIndex]`的log到state machine。这里apply的是上一次的log。因为leader commit后，follower才能commit，本次log leader还没有commit
	- 什么情况会出现leaderCommit > commitIndex呢，当follower掉线了的时候
- 
# matchIndex