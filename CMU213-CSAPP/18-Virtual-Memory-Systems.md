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
4. 将物理地址传递给内存获取数据，