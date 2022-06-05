# Trees Indexes

- A table index is a **replica** of a **subset of a table’s columns** that is organized in such a way that allows the DBMS to find tuples more quickly than performing a sequential scan. 

- The DBMS ensures that **the contents of the tables** and **the indexes** are always in **sync**.

- It is the DBMS’s job to figure out(找出) the **best indexes** to use to execute queries. There is a trade-off on the number of indexes to create per database (indexes use storage and require maintenance). 占用磁盘和buffer pool、表内容和索引同步的开销

## B+ Tree

- A B+Tree is a **self-balancing** tree data structure that keeps data **sorted** and allows searches, sequential access, insertion, and deletions in **O(log(n))**.

- Optimized for systems that read and write  large blocks of data. 能够在磁盘非常缓慢，内存有限的情况下进行高效的索引查找。

- Every node in a B+Tree contains an array of key/value pairs
  ![](CMU445-7-Trees-Indexes1/07-trees1_12.JPG)
  - Arrays at every node are (almost) sorted by the keys.
  - Two approaches for leaf node values
    - Record IDs: A pointer to the location of the tuple
    - Tuple Data: The actual contents of the tuple is stored in the leaf node

## Leaf Nodes

![](CMU445-7-Trees-Indexes1/07-trees1_16.JPG)

上图为教科书式结构，key和value存储在一起，pageID指向兄弟节点。但在实际数据库中是以下面的形式将数据分开存储的，存在像slot header的内容，可以从中知道树的高度，还有多少个空闲的slot，前一个和后一个节点是什么。分开存储key和value，有效利用缓存，当查找的时候，只使用到key，可以只把key加载到内存，如果像上面key和value一样混在一起，则还把value加载进来，浪费缓存。

![](CMU445-7-Trees-Indexes1/07-trees1_18.JPG)

B-Tree vs B+Tree：

- space 
  - The original **B-Tree** from 1972 stored `keys + values` in **all nodes** in the tree. 不会有重复的key，每个key只出现在一个节点，空间效率高。
  - A **B+Tree** only stores values in leaf nodes. Inner nodes only guide the search process. inner节点会有某个key当作路标，所以会有重复key。

- update node
  - 当修改B-Tree node的时候可能会给其他节点也带来影响（为了平衡可能需要修改向上的节点和向下的节点），这样latch锁也需要额外在两个反向上加。
  - B+Tree只修改叶子节点，但是结果只会影响到向上的结果，只加一个latch锁就行。

## Insertion

1. Find correct leaf L.
2.  Add new entry into L in sorted order
   -  If L has enough space, the operation done.
   - Otherwise split L into two nodes L and L2：找到叶子节点的中间位置，将中间位置左边所有key放入一个节点，右边的放到另外一个节点。将中间的key（保护新插入的值算出的）复制到上面作为新的根节点。

---

插入2 6 4 1 5，max degree=3(non-null children, Every inner node with k keys has k+1 non-null children)
https://www.cs.usfca.edu/~galles/visualization/BPlusTree.html

![](CMU445-7-Trees-Indexes1/2022-06-05_164158.png)

## Clustered Indexes

数据库默认情况是以任何顺序将tuple插入到任何的page中，有时想让数据（比如主键）以某种形式进行排列，创建表的时候可以创建一个聚簇索引，数据库系统会排序存储数据在磁盘上，这样只读取一部分page能找到对应的数据，对于某些任务（比如根据主键进行范围查询）会很有用。

某些系统会默认使用，比如MySQL将tuple保存到叶子节点上（索引在磁盘上保存），保证磁盘上的page中的tuple都是以主键顺序排序的，如果没有主键，MySQL会自动以record id（tuple实际位置）之类的创建一个主键。

## Select Conditions

假设在两列上面定义一个复合索引（composite key）

- Find key=(A, B)：先比较第一个key，再比较第二个key（这里图的比较应该不取等，如果取等，AC应该存放在第一个node）
  ![](CMU445-7-Trees-Indexes1/07-trees1_27.JPG)
- Find key=(A, *)：找到第一个叶子结点后，沿着叶子结点找直到遇到大于A为止。
  ![](CMU445-7-Trees-Indexes1/07-trees1_29.JPG)
- Find key=(*, B)：根据第二个key多次找出所有的可能叶子，然后将所有符合结果整合。查找过程中会用不同的实际值代替`*`，并对数据进行多次遍历。oracle称为skip scan。
  ![](CMU445-7-Trees-Indexes1/07-trees1_32.JPG)

## Node Size

- 一般可以将B+Tree中的node当作表中的page来思考，存储设备越慢，B+Tree 的最佳节点大小就越大。HDD ~1MB、SSD: ~10KB 、In-Memory: ~512B

- 对于Leaf Node Scans，node大小适合大点，可以进行更多的循序扫描。对于Root-to-Leaf Traversals，node大小适合小点。

## Merge Threshold

有时候节点并未达到half full的情况就得对节点进行合并。但是在实际上并不会立即进行合并操作，因为可能下次操作适合，又往节点中插入了些数据，又得将它进行拆分，合并的代价是昂贵的。

可以放宽要求，在后台定期调整树的平衡。甚至有时候会直接重建整一棵树，修复所有的问题，比如银行每周日早上关闭服务，可能做的一件事情就是重建索引。

## Variable Length keys

- Pointers：节点保存的是指向属性或者tuple的指针（比如record id），得重新拿page看下实际保存的值，速度很慢。
- Variable Length Nodes：允许一个节点的大小根据它所保存的东西来变化，因为我们想让page大小在buffer pool和磁盘中始终是一样，就无须去担心该如何找到空闲空间将数据放进去，这是个糟糕的想法。
- Padding：使用null或者0填充，以此来保存一样大小，PG采用此方式，这是一种取舍，为了保存数据，得浪费空间。
- Key Map/Indirection：Embed an array of pointers that map to the key + value 
  list within the node. 和slotted page的布局很像，根据offset确定数据。key+value从后往前存，sorted key map从前往后存。每个node的大小是固定的，如果这个node没有足够的空间，可以使用一个overflow page链接到这里。
  ![](CMU445-7-Trees-Indexes1/07-trees1_38.JPG)

​		指针数据每个元素一般有16bit大小，空间充足，可以将每个字符串的首字母放到数组，如果第一个字符没有一样，则可以直接遍历下一个，这些都是在内存中做的（node的大小和磁盘中的page大小可能不一样）。
​		![](CMU445-7-Trees-Indexes1/07-trees1_39.JPG)