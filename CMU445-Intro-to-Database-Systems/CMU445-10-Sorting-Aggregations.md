# Query Plan

![](CMU445-10-Sorting-Aggregations/10-sorting_6.JPG)

A和B使用某种join算法计算在一起，A的数据可能没法放在内存中，B中的数据甚至输出的结果也可能没法放在内存中，所以我们需要一种能够处理这种情况的join算法，使用buffer pool manager来处理溢出到磁盘的情况。

# Sorting Algorithms

- Why do we need to sort
  1. order by
  2. distinct
  3. Bulk loading sorted tuples into a B+Tree index is faster.
  4. group by

- If data fits in memory, then we can use a standard sorting algorithm like quick-sort.
- If the data does not fit, then the DBMS needs to use **external sorting** that is able to spill to(*溢出到*) disk as needed and **prefers sequential** over random I/O.

## External Merge Sort

The standard algorithm for sorting data which is too large to fit in memory is **external merge sort**. 

It is a divide-and-conquer(*分治*) sorting algorithm that splits the data set into separate **runs**(*更小的数据集*) and then sorts them individually(*单独排序*). It can spill runs to disk as needed then read them back in one at a time. 

The algorithm is comprised of two phases:

- **Sorting**: First, the algorithm sorts small chunks of data that fit in main memory, and then writes the sorted pages back to disk.
- **Mergeing**: Combine sorted sub-files into a single larger file.

### 2-way External Merge Sort

- The algorithm **reads each page** during the sorting phase, sorts it, and writes the sorted version back to disk. 
- Then, in the merge phase, it uses **three buffer pages**. It reads two sorted pages in from disk, and merges them together into a third buffer page.
  - Whenever(*每当*) the third page fills up, it is written back to disk and replaced third page with an empty page. （要合并的结果有2个page那么大，但是只有一个page用于保存结果，所以写满后得先写回到磁盘然后清空再继续处理）
  - Each set of sorted pages is called a **run**.

Data set is broken up into **N** pages. The DBMS has a finite(*有限的*) number of **B** buffer pages  to hold input and output data. （Postgresql中working memory，一个查询在进行中间操作(构建一个hash table，排序...)时被允许使用的内存量）

![](CMU445-10-Sorting-Aggregations/10-sorting_14.JPG)

![](CMU445-10-Sorting-Aggregations/10-sorting_15.JPG)

2-PAGE runs：一个run有两个page大

