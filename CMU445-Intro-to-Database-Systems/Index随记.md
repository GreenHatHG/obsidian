# Basic Concepts
- An attribute or set of attributes used to look up records in a ﬁle is called a `search key`. [**P653**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=042f6697-ee66-281e-e3a6-4c191b78a1c8&page=653&rect=128.880,144.462,499.525,168.929)
	- Using our notion of a search key, we see that if there are several indices (index 复数) on a ﬁle, there are several search keys. [**P653**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=02c42e23-0729-82f8-5a85-15f996f8813a&page=653&rect=128.881,105.582,499.432,130.049) 如果一个文件上有几个 index，那么就有几个 search key

# Ordered Indices
- All ﬁles are ordered sequentially on some search key. Such ﬁles, with a `clustering index` on the search key, are called index-sequential ﬁles. [**P654**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=6ad5853f-8064-58e7-34da-6a3eea81144d&page=654&rect=160.318,183.283,530.855,220.709)
	- They are designed for applications that require both sequential processing of the entire ﬁle and random access to individual records. [**P654**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=2e856f3f-545e-dac0-3ec3-91eebeb7de39&page=654&rect=160.317,157.423,530.895,181.890) 在磁盘上有序存放，减少访问时间
	- Figure 14.1 shows a sequential file of *instructor* records taken from our university example. In the example of Figure 14.1, the records are stored in sorted order of instructor ID, which is used as the search key. [**P654**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=5e15d362-a317-1a07-7b83-4532eeb90cf3&page=654&rect=160.316,105.583,531.079,143.010)
	  ![[booknote/books-data/book/(annots)Database-System-Concepts.pdf/p654r149.570,447.500,533.690,668.060z2i(ca10f0d0-ffb9-3261-6eb3-9effa031c366).png#center|640]]

## Dense and Sparse Indices
- An `index entry`, or index record, consists of a search-key value and pointers to one or more records with that value as their search-key value. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=5131d2e3-5956-8a62-ca9b-6208cc8b1dd3&page=655&rect=128.880,617.862,499.476,642.329) 每个 index 由 search key 和对应指向其完整记录的 record pointer 组成
	- The pointer to a record consists of the identiﬁer of a disk block and an oﬀset within the disk block to identify the record within the block. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=1a21647d-1617-2265-5a80-4a9005e11636&page=655&rect=128.880,592.002,499.497,629.369)
- In a `dense index`, an index entry appears for **every search-key value** in the ﬁle. 
	- In a `dense clustering index`, the index record contains the search-key value and a pointer to the ﬁrst data record with that search-key value. 
	- The rest of the records with the same search-key value would be stored sequentially after the ﬁrst record, since, because the index is a clustering one, records are sorted on the same search key. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=3701de3c-1ac5-de05-25e3-7066d805e304&page=655&rect=148.320,487.782,500.267,566.341)
	- In a `dense nonclustering index`, the index must store a list of pointers to all records with the same search-key value. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=8980a128-32ca-25d2-dbc5-03f44c968cfc&page=655&rect=148.320,461.862,499.499,486.329)
	![[booknote/books-data/book/(annots)Database-System-Concepts.pdf/p656r118.470,445.200,542.900,677.280z2i(f2b19a03-8efb-d5f9-5f89-4071848c1e24).png#center|707]]
- In a `sparse index`, an index entry appears for **only some of the search-key values**. 
	- Sparse indices can be used only if the relation is stored in sorted orde rof the search key; that is, if the index is a clustering index. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=640eb457-48d1-5fb4-9938-4c7247d8f5fa&page=655&rect=148.320,417.042,499.507,456.781) 文件存储方式是聚类索引才能使用稀疏索引
	- To locate a record, we ﬁnd the index entry with the largest search-key value that is less than or equal to the search-key value for which we are looking. We start at the record pointed to by that index entry and follow the pointers in the ﬁle until we ﬁnd the desired record. [**P655**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=5c0ba1a4-3a9e-b296-67a9-b93aa7880148&page=655&rect=148.320,352.302,499.563,402.629) 根据 search key 找到最大那个 index，然后找到对应文件，根据文件顺序使用 record pointer 找到对应的 record
	![[booknote/books-data/book/(annots)Database-System-Concepts.pdf/p656r111.560,81.820,540.020,311.020z2i(3454e03e-9a64-8929-beb1-2451dc8b390b).png#center|714]]
	找 id 为22222的 record，先在 index 中找到 10101，然后定位到第一个文件，顺着 record pointer 往下找
	
- A good compromise (*折衷方案*) is to have a sparse index with one index entry per block. 
	- The reason this design is a good trade-oﬀ(*很好的权衡*) is that the dominant cost (*主要成本*) in processing a Database request is the time that it takes to bring a block from disk into main memory. 
	- Once we have brought in (*导入*) the block, the time to scan the entire block is negligible (*忽略不计*).  [**P656**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=0ac93e6d-4a91-836a-72b7-41459c7bdf1a&page=656&rect=215.365,324.642,530.963,336.149)
	- We must consider the case where records for one search-key value occupy several blocks [**P657**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=de519364-baa8-8ce5-6cd0-a07750675540&page=657&rect=128.880,348.102,499.498,372.569)

# B+-Tree Index Files
- A B+-tree index takes the form of a balanced tree in which every path from the root of the tree to a leaf of the tree is of the same length. 
- Each nonleaf node in the tree (other than the root) has between $⌈n∕2⌉$ and n children, where n is ﬁxed for a particular tree; 
- the root has between 2 and n children. [**P663**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=76f58fca-4ab6-3af4-01c8-5496ce471cf9&page=663&rect=128.879,379.662,500.321,442.949)
## Insert
- In general, we take the n search-key values (the n−1 values in the leaf node plus the value being inserted), and put the ﬁrst $⌈n/2⌉$ in the existing node and the remaining values in a newly created node. [**P670**](obsidian://booknote?type=annotation&book=book/Database-System-Concepts.pdf&id=9ba56c63-9e92-0c73-c18f-8dcee0a7447e&page=670&rect=230.975,103.708,531.820,118.656)
![[booknote/books-data/book/(annots)Database-System-Concepts.pdf/p665r53.920,571.690,525.780,677z2i(2c45d1a9-17ae-fe34-998a-e017b10ba0d7).png#center|786]]

![[booknote/books-data/book/(annots)Database-System-Concepts.pdf/p671r94.170,100.460,522.560,239.160z2i(65005674-9bce-e7d8-4683-a14421ec2798).png#center|714]]
