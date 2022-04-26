# Cache Memories

- Cache memories are small, fast SRAM-based memories managed automatically in hardware
  - Hold frequently accessed blocks of main memory
- CPU looks first for data in cache

![cache-memories](12-Cache-Memories/2022-04-22_221529.png)

## General Cache Organization (S,E,B)

![organization](12-Cache-Memories/2022-04-22_221928.png)

- 可以把Cache Memory的组织形式看成是一个二维数组
- valid bit指示着这些数据block是否有实际意义

## Cache Read

当程序执行一条引用内存中某个数据的指令时，CPU 将该地址发送到缓存（cache），并要求缓存返回该地址处的数据，Cache拿到地址后，定位方式如下：

![png](12-Cache-Memories/2022-04-22_222707.png)

1. 定位set：从地址中提取set index找到特定set
2. 检查tag：查看set中所有line的tag，找到与地址中tag一样的tag，并检查是否有效，这样就对应到了具体某个line
3. 使用block offset定位数据从line中第几个block开始读，具体读多少个看是什么类型的，比如int就4bytes

### Example: Direct Mapped Cache(E=1)

直接映射缓存（Direct Mapped Cache）

![png](12-Cache-Memories/2022-04-22_234551.png)

定位到第1个set后（index从0开始）

![png](12-Cache-Memories/2022-04-22_234848.png)

tag不匹配的话，旧的line将被新的line覆盖，并且tag也要更新

### Direct Mapped Cache原理

假设内存系统由16个字节组成，地址4位，切分出每个block包含2个字节，缓存由4个set组成，每个set一个block。执行下面的5个指令内存最终形态：

![png](12-Cache-Memories/2022-04-22_235733.png)

变化的过程：

1. 刚开始处于默认的情况

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 0 |  ?  | ? |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** |      |       |  |

2. 接收到set index=0的指令，无效，所以miss。然后从内存中获取该block放到缓存中。`M[0-1]`代表从内存0~1字节处加载数据

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** |      |       |  |

3. 接收到set index=0，tag=0的指令，有效，hit

4. 接收到set index=3（二进制为11），同样miss并从内存中拿数据

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

5. 接收set index=0，tag=1的指令，但是set 0被`tag=0 block M[0-1]`占据了，所以是miss，然后从内存中拿数据覆盖，出现了Conflict miss。

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  1  | M[8-9] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

6. 同样set index=0，又miss不得不替换，唯一原因是每个set只有一个line。

    |     | v | Tag | Block |
    | :--: | :--: | :---: | :--: |
    |  **Set 0**  | 1 |  0  | M[0-1] |
    | **Set 1** |      |       |  |
    | **Set 2** |      |       |  |
    | **Set 3** | 1 | 0 | M[6-7] |

### E-way Set Associative Cache(E=2)

![png](12-Cache-Memories/2022-04-23_142444.png)

定位到第1个set后，现在一个set有两个line

![png](12-Cache-Memories/2022-04-23_143012.png)

然后从这两个line中搜寻可匹配的tag，同时得看valid。这是在硬件层次的比较，随着E越来越大，硬件越来越贵。

没有匹配到，则从set选出一个line进行替换，策略为random或者LRU等等

### 2-Way Set Associative Cache原理

假设内存系统由16个字节组成，地址4位，切分出每个block包含2个字节，缓存由2个set组成，每个set两个block。执行下面的5个指令内存最终形态：

![png](12-Cache-Memories/2022-04-23_143524.png)

变化的过程：

1. 刚开始处于默认的情况

    |           | v    | Tag  | Block |
    | --------- | ---- | ---- | ----- |
    | **Set 0** | 0    | ?    | ?     |
    | **Set 0** | 0    |      |       |
    | **Set 1** | 0    |      |       |
    | **Set 1** | 0    |      |       |

2. 接收到set index=0的指令，无效

    |           | v    | Tag  | Block  |
    | --------- | ---- | ---- | ------ |
    | **Set 0** | 1    | 00   | M[0-1] |
    | **Set 0** | 0    |      |        |
    | **Set 1** | 0    |      |        |
    | **Set 1** | 0    |      |        |

3. 接收到set index=0，tag=0的指令，有效，hit

4. 接收到set index=1，miss，随机挑选一个line替换

    |           | v    | Tag  | Block  |
    | --------- | ---- | ---- | ------ |
    | **Set 0** | 1    | 00   | M[0-1] |
    | **Set 0** | 0    |      |        |
    | **Set 1** | 1    | 01   | M[6-7] |
    | **Set 1** | 0    |      |        |

5. 接收到set index=0的指令，miss，因为有两个line，所以可以替换到空的line上

    |           | v    | Tag  | Block  |
    | --------- | ---- | ---- | ------ |
    | **Set 0** | 1    | 00   | M[0-1] |
    | **Set 0** | 1    | 10   | M[8-9] |
    | **Set 1** | 1    | 01   | M[6-7] |
    | **Set 1** | 0    |      |        |

6. 接收到set index=0的指令，hit

## Cache Write

- 存在多个数据副本：L1、L2、L3 cache，Main Memory，Disk。k层会建立k+1层数据的缓存。

- 对缓存中的block进行写入的时候（write hit），有两种选择：
  - Write-through：更新缓存，然后立即将其写入内存中，让缓存和内存的内容始终保持一致，但是访问内存很慢（相对于高速缓存来讲）。
  - Write-back：不会立马写回内存，直到缓存想要覆盖该数据为止。需要在line中有一个dirty bit记录block的数据是否已经更新过。

- write-miss（正在写的数据并不包含在缓存中的任何block中）时候：
  - Write-allocate：从内存中获取数据，更新cache line
  - No-write-allocate：直接写入到内存，不加载到缓存

- 一般使用：
  - Write-through+No-write-allocate
  - Write-back+Write-allocate：不会立马将数据写回内存，每当出现一个write miss，就在写入到cache，是一个比较简单的模型。

### Intel Core i7 Cache Hierarchy

![png](12-Cache-Memories/2022-04-23_172623.png)

- regs：寄存器
- d-cache：数据缓存
- i-cache：指令缓存
- L2 unified cache：统一包含了数据和指令

## Memory Mountain

memory mountain 绘制了一个名叫读取吞吐量（read throughput）或读取带宽（read bandwidth）的度量图，即每秒从内存读取的字节数。主要用于测量程序的spatial、temporal locality。

### Memory Mountain Test Function

```c++
//mountain/mountain.c
long data[MAXELEMS];  /* Global array to traverse */

// test - Iterate over first "elems" elements of array “data” with stride of "stride", using using 4x4 loop unrolling.    
int test(int elems, int stride) {
    long i, sx2=stride*2, sx3=stride*3, sx4=stride*4;
    long acc0 = 0, acc1 = 0, acc2 = 0, acc3 = 0;
    long length = elems, limit = length - sx4;
    /* Combine 4 elements at a time */
    for (i = 0; i < limit; i += sx4) {
        acc0 = acc0 + data[i];
        acc1 = acc1 + data[i+stride];
        acc2 = acc2 + data[i+sx2];
        acc3 = acc3 + data[i+sx3];
    }
    /* Finish any remaining elements */
    for (; i < length; i++) {
        acc0 = acc0 + data[i];
    }
    return ((acc0 + acc1) + (acc2 + acc3));
}
```

示例输出：

```c++
elems=length=[20], stride=[2], limit=[12]
access i=[0] i+stride=[2] i+sx2=[4] i+sx3=[6]
access i=[8] i+stride=[10] i+sx2=[12] i+sx3=[14]
access i=[16]
access i=[17]
access i=[18]
access i=[19]

0 2 4 6 8 10 12 14 16 17 18 19
```

```c++
elems=length=[60], stride=[7], limit=[32]
access i=[0] i+stride=[7] i+sx2=[14] i+sx3=[21]
access i=[28] i+stride=[35] i+sx2=[42] i+sx3=[49]
access i=[56]
access i=[57]
access i=[58]
access i=[59]

0 7 14 21 28 35 42 49 56 57 58 59
```

使用不同的步长测试，首先调用test()预热一次缓存（warm up the caches），然后再调用test()测试读取吞吐量，记录每执行一次test读取所消耗的时间，将其转换为MB/s。

![png](12-Cache-Memories/2022-04-26_191234.png)

- y轴：数组所读元素数量 
- 随着步长增加，空间局限性影响减少
- 随着读取数量变多，空间和时间局限性影响减少
- 在山顶吞吐量最大，具有最好的空间时间局部性，达到14GB/s吞吐量。在山底，只有大概100MB/s，需要不断去内存中读取数据
- 空间局限性山脊（Ridges of temporal locality），L1抖动小，性能稳定（从左到右看）。因为步长的原因，时间局部性降低，L2，L3,Mem就会很抖。
