# nextIndex
- 官方描述：for each server, index of the next log entry  to send to that server (initialized to leader last log index + 1)
- `nextIndex[i]`代表着对第i个follower发起Append Entries RPC时**尝试**replicated log的位置，仅仅是猜测并不是真实的，并且出现`log inconsistency`会将该值回退。
- leader收到Append Entries RPC回复后只有是因为`log inconsistency`才能更新nextIndex
- 
# commitIndex
- 官方描述：for each server, index of highest log entry known to be replicated on server  (initialized to 0, increases monotonically)
-  If leaderCommit > commitIndex, set commitIndex = min(leaderCommit, index of last new entry)
	- leader发送带有log的Append Entries RPC给follower，append log的follower达到majority后，leader commit该log，并修改commitIndex
	- 第二次发送RPC时候，会检