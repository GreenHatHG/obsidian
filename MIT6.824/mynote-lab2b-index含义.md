# nextIndex
1. 官方描述：for each server, index of the next log entry  to send to that server (initialized to leader last log index + 1)
2. leader保存该数组变量，由leader更新。
3. `nextIndex[i]`代表着对第i个follower发起Append Entries RPC时**尝试**replicated log的位置，仅仅是猜测并不是真实的，并且出现`log inconsistency`会将该值回退。所以`nextIndex[i]`需要比`matchIndex[i]`要大。
4. leader收到Append Entries RPC回复后只有是因为`log inconsistency`才能更新nextIndex。
5. 更新nextIndex的三个时机
	- leader election成功时候，需要更新nextIndex为`leader last log index + 1`
	- AppendEntries RPC返回success，代表已经成功replicated log
	- `log inconsistency`时候回退nextIndex
# matchIndex
1. 官方描述：for each server, index of highest log entry known to be replicated on server  (initialized to 0, increases monotonically)
2. leader保存该数组变量，由leader更新。
3. 更新matchIndex时候，应该取自args的值，因为nextIndex和raft中的logEntries的值可能已经发生了变化。`matchIndex = prevLogIndex + len(args.entries)`
4. 更新matchIndex的两个时机
	- 
# commitIndex
1. 官方描述：index of highest log entry known to be  committed (initialized to 0, increases  monotonically)
2. commitIndex并不是只有leader才有的，所有server的commitIndex应该是一致的。
3. If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
	- leader发送带有log的Append Entries RPC给follower，append log的follower达到majority后，leader commit该log，并更新commitIndex
	- 第二次发送RPC时候，因为leaderCommit大于follower的commitIndex，代表着leader已经commit了新的log，所以follower根据上述规则更新自己的commitIndex
	- 根据commitIndex > lastApplied，就会apply `[lastApplied+1, commitIndex]`的log到state machine。这里apply的是上一次的log。因为leader commit后，follower才能commit，本次log leader还没有commit
4. 更新commitIndex的时候，需要注意Figure8的条件，leader只能apply currentTerm的log时候顺便apply了之前的term的log，而不能直接apply之前term的log