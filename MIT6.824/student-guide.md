https://thesquareplanet.com/blog/students-guide-to-raft/
# Append Entries(AE) RPC一些细节
1. 收到HeartBeat后执行Figure2中的检查通过后才能重置election timer
2. 当存在conflict entry时才能截断该点和该点之后的日志，而不是根据prevLogIndex直接截断后面所有的日志
# Livelocks
- Livelocks：跑测试时候raft没有任何进展，没有继续将状态流转下去
- 常见场景：没有触发leader election、一旦election成功，其他节点就开始选举，导致刚选出来的leader退位。
## 正确重置election timer
只有在以下情况下才能重置：
1. follower收到AE且检查后（比如检查args里面的term）重置
2. follower timer触发，转变为candidate后
3. **follower给candidate成功投票后**
## 正确触发election
根据Figure2决定何时触发election，特别是假如candidate正在执行election的过程中，这时候timer触发了，应该开启另外一个election
## 确保正确遵守了Figure2中Rules for Servers
第二条规定：`If RPC request or response contains term T > currentTerm: set currentTerm = T, convert to follower`
例如，如果follower在currentTerm已经投票了，同时接收到的RequestVote RPC的term比currentTerm大，这时候应该采用最新的term并重置votedFor，接着处理RPC
# Incorrect RPC handlers
- 如果Figure2中的步骤显示`reply false`，这时候应该直接返回不执行后面程序
- 如果AE中的prevLogIndex大于lastLogIndex，直接reply false
- 即使AE中不带logEntries，也应该执行Figure中的第二条检查
- AE中的第5步取min是必须的
- 确保检查`up-to-date log`规则按照section5.4来，而不是单纯检查长度
# Failure to follow The Rules
- 当`commitIndex>lastApplied`时候就应该apply相关log。可以延迟一会再执行，但是一定要保证针对某个entry只apply一次
- leader发出的AE只能是因为`log inconsistency`被拒绝