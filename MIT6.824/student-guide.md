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

