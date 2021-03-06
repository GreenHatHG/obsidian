# The-Memory-Hierarchy

## RAM

- Random-Access Memory，RAM通常被封装为一个芯片(chip)
- 基本存储单元是cell（每个cell存储1 bit）
- 多个RAM chip组成memory
- RAM分两种：SRAM(Static RAM)、DRAM(Dynamic RAM)
   ![png](11-The-Memory-Hierarchy/Pastedimage20220417181908.png)
  - Trans per bit：每bit需要晶体管
  - DRAM需要不断刷新，如果不施加电压，就会失去电荷，而SRAM插入并充电后，不需要刷新
  - SRAM比DRAM可靠得多，因此不需要进行错误检测和纠正（EDC），由于这种差异，SRAM比DRAM计算成本会更小、更快

## Nonvolatile Memories

ROM(Read-only memory)最初设定是出厂时候设定数据后就不能修改了。随着技术的发展，出现了Flash memory(EEPROM)，提供了block-level数据擦除功能，缺点是大约十万次擦除后就会磨损。

## CPU and Memory

内存使用一种称之为总线(bus)的电线连接到CPU，数据在电线上流动。
内存操作读取和写入通常可能是50纳秒到100纳秒而寄存器之间发生的操作是亚纳秒（subnanosecond）
![png](11-The-Memory-Hierarchy/Pastedimage20220418212908.png)

## Memory Read Transaction

`Load operation: movq A, %rax`，将地址A处的8 bytes放到%rax

1. CPU places address A on the memory bus.
   ![png](11-The-Memory-Hierarchy/Pastedimage20220418213242.png)
2. Main memory reads A from the memory bus, retrieves word x, and places it on the bus.
   ![png](11-The-Memory-Hierarchy/Pastedimage20220418213754.png)
3. CPU read word x from the bus and copies it into register %rax.
   ![png](11-The-Memory-Hierarchy/Pastedimage20220418213911.png)

## Memory Write Transaction

1. CPU places address A on bus. Main memory reads it and waits for the corresponding data word to arrive.
![png](11-The-Memory-Hierarchy/Pastedimage20220418214119.png)
2. CPU places data word y on the bus.
![png](11-The-Memory-Hierarchy/Pastedimage20220418214149.png)
3. Main memory reads data word y from the bus and stores it at address A.
![png](11-The-Memory-Hierarchy/Pastedimage20220418214217.png)

## Disk

- SRAM access time is about  4 ns/doubleword, DRAM about  60 ns
  - Disk is about 40000 times slower than SRAM,  2500 times slower then DRAM.
- 磁盘呈现给CPU的是逻辑块0,1,2,...（Logical Disk Blocks），每一块都是扇区大小的倍数，磁盘控制器（disk controller）维护逻辑块和实际物理扇区之间的映射。
  ![png](11-The-Memory-Hierarchy/Pastedimage20220418221050.png)

## Reading a Disk Sector

1. CPU通过将command、logical block number和destination memory address（将数据放在内存的地址）写入与磁盘控制器相关联的端口(地址)来启动磁盘读取。
 ![png](11-The-Memory-Hierarchy/Pastedimage20220418222047.png)
2. 磁盘控制器将数据通过l/O bridge经由l/O总线直接复制到主内存（main memory），而无需通知 CPU
   ![png](11-The-Memory-Hierarchy/Pastedimage20220418222350.png)
3. 当DMA传输完成时，磁盘控制器用中断通知CPU
   ![png](11-The-Memory-Hierarchy/Pastedimage20220418222552.png)
4. 如果某处有某个程序在等待将该数据读入内存，那么现在CPU可以执行该程序并处理该内存

## Solid State Disks (SSDs)

![png](11-The-Memory-Hierarchy/Pastedimage20220418223312.png)

- SSD中的Flash translation layer扮演磁盘控制器的角色
- 以页（page）为单位读取数据，页只有在块（Block）擦除（erase）后才能写入

## The CPU-Memory Gap

![The-CPU‐Memory-Gap](11-The-Memory-Hierarchy/2022-04-20_210246.png)

CPU的速度和存储的速度越差越大，这个短板制约着计算的速度。弥合CPU和内存之间这种差距的关键是这个名为locality的计算机程序的基本属性。

## Locality

### Principle of Locality

局部性原则(Principle of Locality): 程序倾向于使用地址接近或最近使用过的地址的数据和指令。

- 时间局部性(Temporal locality): 最近引用的item很可能在不久的将来再次引用
- 空间局部性(Spatial locality): 访问该item附近的item的几率很高

```c++
sum = 0; 
for (i = 0; i < n; i++) 
 sum += a[i]; 
return sum;
```

每循环一次都会i+1，然后读`a[i]`，这称为跨步(stride)引用模式，对`a[i]`的引用体现了空间局部性，对sum的引用体现了时间局部性。

### 对locality有性质上的认识

良好的locality会有良好的性能

```c++
int sum_array_rows(int a[M][N]) 
{ 
    int i, j, sum = 0; 
 
    for (i = 0; i < M; i++) 
        for (j = 0; j < N; j++) 
            sum += a[i][j]; 
    return sum; 
}
```

逐行访问的方式比按列访问的方式要好的多，二维数组每个数组元素在分配空间的时候是一段连续内存，按列访问就是在跨度很大的地址间跳来跳去。

```c++
int sum_array_cols(int a[M][N]) 
{ 
    int i, j, sum = 0; 
 
    for (j = 0; j < N; j++) 
        for (i = 0; i < M; i++) 
            sum += a[i][j]; 
    return sum; 
} 
```

## Memory Hierarchies

存储成本越低，存储容量越大，防止同理；存储设备和CPU速度之间的差异；写的好程序往往表现出好的局部性

基于这三点属性互补，提出了内存层次结构：组织内存和存储系统的设计

![ExampleMemoryHierarchy](11-The-Memory-Hierarchy/2022-04-20_213921.png)

- 在此层次结构的顶部，拥有更小、更快、更昂贵的存储设备，在顶部执行一条指令时可以对寄存器读写
- 在处理器芯片内部放置了一个或多个由SRAM构建的高速缓存存储器（即所谓的高速缓存），这些缓存因为它们是由SRAM制成的，所以它们的大小是以MB来计算的。
- 主存由DRAM构建的，大小可能是几G或者几十G
- 此层次结构中的每个级别都会保存从下一个较低级别存储设备检索而来的数据，寄存器中所保存的数据，来自于L1 cache（L1高速缓存）以此类推。

## Cache

- 一个更小、更快的存储设备，充当较大、较慢设备中部分数据的暂存区。内存层次结构的基本思想是：对于每一个k，在k层的更快、更小的设备作为在k+1层的更大、更慢的设备的缓存。
- 为什么内存层次会起作用？由于局部性，程序访问级别k上的数据比访问级别k+1上的数据更频繁。因此，在k+1级的存储可以更慢，从而更大和更便宜。
- 内存层次结构创造了一个大的存储池，其成本与靠近底部的廉价存储一样高，但它以靠近顶部的快速存储的速度向程序提供数据。（其实就好像利用了各种特性花更少的钱组出更好的配置）
- 基于缓存的内存层次结构通过利用局部性缩小了CPU、内存、大容量存储之间的差距

![Caching-in-the-Mem.Hierarchy](11-The-Memory-Hierarchy/2022-04-20_232539.png)

- 缓存管理：将item放在缓存哪个位置
- TLB：这是在虚拟内存中使用的缓存

## General Cache Concepts

![GeneralCacheConcepts](11-The-Memory-Hierarchy/2022-04-20_222520.png)

- 数据以block大小为传输单位在内存和缓存之间进行传输。假如CPU请求block4，它会查看数据是否在cache中，若不在，cache会从内存中获取这个block4，这个block就会从内存拷贝到cache中，并覆盖cache中现有的block。
- 如果要读取的数据位于cache则可以直接返回，这称为hit，反之称为miss

### Types of cache missess

- Cold(compulsory) miss: 缓存中没有任何内容，随着往里面添加更多数据，增加了命中的可能性，这叫预热数据
- Capacity miss：缓存大小是固定的，当局限性需要的缓存大于缓存本身就会不够空间，导致miss
- Conflict miss：大多数高速缓存限制k+1级的block在k级存放的位置，例如k+1级的block i必须放在k级的block i % 4处。但是可能block j，block k的数据也得放在该位置，就会出现冲突。这个与放置block的算法有关。

