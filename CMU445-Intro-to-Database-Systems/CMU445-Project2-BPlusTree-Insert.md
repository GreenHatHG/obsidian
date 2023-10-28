单线程版 B+树插入操作

# Overview
- **Index**: The index in database system is responsible for fast data retrieval without having to search through every row in a database table, providing the basis for both rapid random lookups (*快速随机查找*) and efficient access of ordered records.
- **B+Tree dynamic index structure**:  It is a balanced tree in which the internal pages direct the search and leaf pages contains actual data entries.
# B+ Tree properties
1. Each node except root can have a maximum of `M` children and at least `ceil(M/2)` children.
2. Each node can contain a maximum of `M–1` keys and a minimum of ceil `(M/2)–1` keys.
3. The root has at least two children and at least one search key.
4. While insertion overflow of the node occurs when it contains more than `M–1` search key values.
-  `M` is the order of B+ tree. It means every node of that Tree can have a maximum of N children.
For more:
[Introduction of B+ Tree - GeeksforGeeks](https://www.geeksforgeeks.org/introduction-of-b-tree/#)
# Tree in lab
举例一个实现后的 b+ tree 如下：
![](CMU445-Project2-BPlusTree-Insert/image-20231028120216283.png)

## Node
设计思考点：
如果要实现一个 tree，首先得考虑每个节点在内存中是怎么组织的，也就是有哪些关键属性，怎么在内存中管理这些 node。

### BufferPoolManager
把 node 再抽象点，其实也不过就是某一块内存数据，在 db 中，内存的管理由BufferPoolManager (bpm) 接管，也就是 lab1 实现的部分。
其管理的单位是 page，也就是每次向 bpm 申请一块内存，返回的都是一个 page，其实在 cpp 中表示就是一个 class Page。
每个 page 的 data_ 大小都是 4096bytes，node 的数据就存放在此。当然 page 还有其他属性，比如 page_id 等，当作 metadata 好管理各个page。
```c++
static constexpr int BUSTUB_PAGE_SIZE = 4096;

class Page {
	public: 
	Page() { ResetMemory(); }
	
    protected:
    static constexpr size_t OFFSET_PAGE_START = 0;

    private:
    char data_[BUSTUB_PAGE_SIZE]{};
	inline void ResetMemory() { memset(data_, OFFSET_PAGE_START, BUSTUB_PAGE_SIZE); }
}
```
### Page
对于 B+Tree 来讲，leaf node 和 internal node 是不一样的，所以这里在 lab 中对应的是 class BPlusTreeInternalPage 和 class BPlusTreeLeafPage，也就是得把从 bpm 申请来的 class Page 中的 data_ 转换为对应 node page。
转换的方法是使用 reinterpret_cast：
```c++
auto *page = reinterpret_cast<InternalPage *>(buffer_pool_manager_->FetchPage(page)->GetData());
```
这里的意思可以简单理解为：不管你是 InternalPage 还是 LeafPage，实际在代码表示就是一串 byte，这些 bytes 存储在 bpm 的 Page 中，在实际使用中才将其表达为是 InternalPage 还是 LeafPage。
