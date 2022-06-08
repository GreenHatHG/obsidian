# Additional Index Usage

## Implicit Index

Most DBMSs automatically create an index to  enforce integrity constraints(*完整性约束*) but not referential  constraints(*引用约束*) (foreign keys).

创建表的时候自动创建索引

![](CMU445-8-Trees-Indexes2/08-trees2 (1)_16.JPG)

对于外键来讲，则不会自动创建，在没有索引的情况，不能使用引用约束，所以得使用unique关键字，自动创建一个索引。每当插入数据到bar表的时候，为了确保能匹配到foo表的数据，可以在索引中查找是否有匹配的数据。

![](CMU445-8-Trees-Indexes2/08-trees2 (1)_20.JPG)

## Partial Indexes

Create an index on a **subset of the  entire table**. This potentially reduces  its size and the amount of overhead(*开销*) to maintain it.

One common use case is to partition indexes by date ranges. Create a separate index per month, year.

```sql
CREATE INDEX idx_foo ON foo (a, b) WHERE c = 'WuTang';
SELECT b FROM foo WHERE a = 123 AND c = 'WuTang';
```

当tuple匹配这个条件后就可以放进这个索引中（a，b也有索引），如果c不是这个字符串，则不能使用索引。

## Covering Indexes

If **all the fields** needed to process the  query are **available in an index**, then  the DBMS does not need to retrieve  the tuple. This reduces contention(*竞争*) on the DBMS's buffer pool resources. 还可能减少了以此磁盘io

```sql
CREATE INDEX idx_foo ON foo (a, b);
# a和b都在索引
SELECT b FROM foo WHERE a = 123;
```

可运用在其他类型查询，比如聚合、join

## Index Include Columns

Embed additional columns in indexes to support index-only queries. These extra columns are only stored  in the leaf nodes and are not part of  the search key.

PostgreSQL最新版和SQL Server支持，MySQL和Oracle不支持。

```sql
CREATE INDEX idx_foo ON foo (a, b) INCLUDE (c);
SELECT b FROM foo WHERE a = 123 AND c = 'WuTang';
```

搜索a的时候使用索引，找到叶子节点，然后顺着叶子节点搜索符合c的值的数据。尽管可以将c也加入到inner node，但是这样的好处是不会让索引整体变得太大。

## Function/Expression Indexes

```sql
#登录日期为周二
SELECT * FROM users WHERE EXTRACT(dow FROM login) = 2;

CREATE INDEX idx_user_login ON users (EXTRACT(dow FROM login));
# 或者使用partial i
CREATE INDEX idx_user_login ON foo (login) WHERE EXTRACT(dow FROM login) = 2;
```



