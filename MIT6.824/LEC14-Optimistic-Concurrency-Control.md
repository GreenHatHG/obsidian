# why are we reading about FaRM
- transactions+replication+sharding
- RDMA NIC巨大的性能潜力
# FaRM对比Spanner
- 两者共同：replicate、2PC
- Spanner：
  1. 已经完善且部署的系统
  2. 专注于跨DC复制同时处理不同地方的数据的事务能力高效
  3. 只读事务TrueTime
  4. r/w事务需要10~100ms
  5. 主要瓶颈：卫星信号传播上的延迟、DC之间的网络延迟
- FaRM：
	1. 研究型，探索RDMA
	2. 所有replica都在同一个DC
	3. RDMA限制了系统的设计：必须使用Optimistic Concurrency Control (OCC)
	4. 简单事务只需要58microseconds，比Spanner快100倍
	5. 主要瓶颈：服务器上的CPU时间
# 整体设计
- Zookeeper+configuration manager，决定存储每个数据分片的服务器哪个是primary哪个是backup
- 每个数据分片分散到一堆primary/backup replication上，比如一个数据分片对应P1、B1，另一个对应P2、B2
    ```
    P1 B1
    P2 B2
    ...
    ```
    只要每个分片有一个可用的replica，系统就依旧可用， f+1 replicas tolerate f failures
- transaction clients（位于服务器上）充当Transaction Coordinator(TC)
# 高性能
- 数据分片到许多服务器(评估90台)上并行处理
- 所有数据位于RAM，使用非易失（non-volatile） RAM避免供电故障
- RDMA：在不对服务器发出中断信号情况下，通过网络接口卡（NIC）接收数据包并通过指令直接对服务器内存中的数据进行读写。即kernel bypass：在不涉及内核的情况下，应用层代码可以直接访问网络接口卡。

# NVRAM

- 不是写入磁盘，消除了巨大的瓶颈。RAM写入需要200ns（nanoseconds），磁盘写入需要10ms（milliseconds），SSD写入需要100us（microseconds）
- 整个DC的电源发生故障后，可能会影响所有的机器。
  - 所以FaRM为每个服务器准备了电池，让机器再坚持10分钟左右。
  - 发生故障后电源系统会通知FaRM，FaRM服务器上的软件会停止所有的事务处理，将每台机器上的RAM数据写入SSD，然后机器关机。
  - 重启后FaRM从SSD恢复RAM中的数据。
  - 本质上，FaRM使用后备电源做到RAM的非易失性，避免供电故障。只对供电故障有用，由于软件bug等导致的崩溃无效，机器重启并丢失RAM所有的内容。这就是为什么除了使用NVRAM以外，FaRM还得为每个数据分片建立多个replica的原因。
- 所以，NVRAM消除了持久性写入的瓶颈，让网络和CPU成为剩下的瓶颈。

# 为什么网络经常是性能瓶颈

![image-20220420081449790](LEC14-Optimistic-Concurrency-Control/image-20220420081449790.png)

1. app运行于用户态，为了发送数据，app得使用内核中的系统调用并且成本不低。
2. socket层会对数据进行缓存，涉及到复制数据，需要花些时间。
3. TCP协议栈，重传、序列化、checksum、flow control等
4. NIC驱动通过NIC往主机内存读取和写入数据包
5. 类似于队列的东西，放着NIC通过DMA访问内存时所拿到的数据，等待内核读取这个队列中的数据包
6. 用于对外发送数据的数据包队列，NIC可以尽可能将数据发送出去
7. NIC通过电缆将bit信息发送到网络上的硬件
8. NIC收到数据包后发送中断信号给内核
9. 内核通过驱动将数据包发送给TCP进行处理
10. 数据包写入buffer，等待应用程序读取数据
11. app读取数据通过系统调用将内核buffer中的数据拷贝到用户态空间。

- CPU耗时操作：系统调用、复制消息、中断。在这种架构下很难做到每秒传输十万个RPC消息（基本远远小于NIC通过网线传输10Gb/s的上限），并且数据库通常需要使用的信息大小很小，在这种情况下，我们很难去写一个RPC软件，使之每秒能够生成10Gbit大小的消息。

# FaRM减少发送数据包的成本措施

## kernel bypass

1. 与其让应用程序通过调用复杂的内核代码来发送所有数据，直接通过对内核保护机制进行配置，以此来让应用程序直接访问NIC（没有系统调用，没有经过内核，没有中断）

2. 通过DMA，app能直接访问应用程序内存，在不需要内核参与的情况下，应用程序可以直接看到接收到的数据包信息。并且发送数据包时候，应用程序也能去创建一些队列，NIC可以直接通过DMA来读取用户RAM数据，并通过网线将数据发送出去

最新的NIC可以通过NIC设置达到这一点，需要应用程序去自行处理TCP那些事情。kernel bypass使用了DPDK的工具包，DPDK则采用轮询方式实现数据包处理过程：DPDK重载了网卡驱动，该驱动在收到数据包后不中断通知CPU，而是将数据包通过零拷贝技术存入内存，这时应用层程序就可以通过DPDK提供的接口，直接从内存读取数据包。

