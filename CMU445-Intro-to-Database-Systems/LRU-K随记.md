在LRU-K算法中，需要记录每个节点的访问次数。因此，可以使用两个双向链表来实现LRU-K算法。一个链表用于按访问时间排序，另一个链表用于按照访问次数排序。

具体地说，一个链表（称为LRU链表）用于存储缓存中的数据，并按访问时间的顺序排列。每当有数据被访问时，就将其移动到链表的头部。另一个链表（称为LFU链表）用于按访问次数排序。每当有数据被访问时，就将其访问次数加1，并将其从LRU链表中移动到LFU链表的相应位置。

在淘汰数据时，可以先检查LFU链表中访问次数最小的节点，如果有多个节点访问次数相同，则选择在LRU链表中最久未使用的节点。这样可以保证缓存中的数据既按照访问时间排序，又按照访问次数排序。


---
当访问次数达到K次后，将数据索引从历史队列移到缓存队列中（缓存队列时间降序）；缓存数据队列中被访问后重新排序；需要淘汰数据时，淘汰缓存队列中排在末尾的数据。

I think it's best described as "When multiple frames have +inf backward k-distance, FIFO algorithm is used to choose victim". Or you can maintain an FIFO queue to record the frames with +inf backward k-distance.

I'm not sure about the context, but if it's about the LRU-K algorithm, then the O'Neil paper says: "In the following discussion, unless otherwise noted, we will measure all time intervals in terms of counts of successive page accesses in the reference string." I'm still reading it, so maybe there are more details on this topic.

He pointed out that you don't really NEED an actual timestamp, so much as a "happens-before-happens-after" ordering of events

Fix or band-aid? A logical counter is generally a good idea, as opposed to relying on system time (which can drift, or jump backwards, or be out of sync across computers, etc)


