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

pageID指向兄弟节点