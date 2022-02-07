# nextIndex
- 官方描述：for each server, index of the next log entry  to send to that server (initialized to leader last log index + 1)
- 
# commitIndex
- 官方描述：for each server, index of highest log entry known to be replicated on server  (initialized to 0, increases monotonically)