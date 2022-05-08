# 18-Virtual-Memory-Systems

## Simple memory system example

### Address Translation Example #1

![png](18-Virtual-Memory-Systems/20220508122617.png)

PPN实际不存在页表中

1. MMU做的第一件事是检查TLB，将VA中的VPN的TLBI(0x3)和TLBT(0x03)提取出来。所以会去查set3找到tag为3的line，找到对应的line并且valid为1，TLB将PPN(0D)返回给MMU
2. MMU使用0D构建物理地址。将VA的VPO复制到PA的PPO，0D作为PA的PPN，由此构成了一个物理地址
3. 将地址发送给cache，提取出CI(0x5)、CT(0x0D)，所以会去查set5找到tag为0xD的line，找到并且valid为1，因为CO为0，所以找到B0(36)
4. cache将该字节通过MMU返回给CPU，并将其存到一个寄存器中。

### Address Translation Example #2

![png](18-Virtual-Memory-Systems/20220508131850.png)

1. VA中的VPN的TLBI=TLBT=0，TLB的set=0&tag=0的line的valid=0，TLB miss
2. 通过VPN=0查找页表，valid=1有效，内存将PTE返回给MMU构造物理地址。
3. MMU用物理地址请求cache，CI=0x8,CT=0x28，set 8中不存在tag为28的line，cache miss
4. 将物理地址传递给内存获取数据

## Case study: Core i7/Linux memory system

![png](18-Virtual-Memory-Systems/18-vm-systems_12.JPG)

单个芯片封装了4个核心，每个核都可以看作一个单独的cpu，可以各自独立的执行指令。

每个核心都有：

- 寄存器、获取指令的硬件(instruction fetch)
- 两个L1 cache：d-cache保存从内存中获取的数据，i-cache保存从code region获取的指令，d-cache只有数据，i-cache只有指令。访问L1大概需要4个CPU周期。
- L2 unified cache：既可以保存指令，又可以保存数据。访问L1大概需要10个CPU周期。

## End-to-end Core i7 Address Translation

![png](18-Virtual-Memory-Systems/18-vm-systems_14.JPG)

## Core i7 Level 1-4 Page Table Entries

![png](18-Virtual-Memory-Systems/18-vm-systems_15.JPG)

这三级的PTE指向的是下一级的页表的地址

CD表示能不能缓存

XD为disable意味着无法从这个page上加载到任何指令

![png](18-Virtual-Memory-Systems/18-vm-systems_16.JPG)

## Cute Trick for Speeding Up L1 Access

![png](18-Virtual-Memory-Systems/18-vm-systems_18.JPG)

因为VPO和PPO都是一样的，所以CI也是一样的，在MMU进行地址转换的同时将CI发送给L1 cache，然后cache做set的查找，找到所有的line后并且MMU完成地址转换，此时就可以根据tag找到特定的line了，有那么一点并行的存在。

