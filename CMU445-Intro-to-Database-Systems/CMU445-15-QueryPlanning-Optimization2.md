# Cost-based Query Optimization

如果要对n张表进行join，总共有4^n(Catalan number)个排列，不可能一一枚举来决定哪个join最优，所以还需要一个成本模型去决定哪条查询成本最低。

衡量SQL的开销指标：

- CPU: 成本小，难以估计
- Disk: Number of block transferred.
- Memory: Amount of DRAM used.
- Network: Number of messages transfered.

It is too expensive to run every possible plan to  determine this information, so the DBMS need a  way to derive(*获取*) this information.

To accomplish this(*为此*), the DBMS stores internal statistics about tables, attributes, and indexes in its internal catalog.

Different systems update them at different times.

# Statistics

