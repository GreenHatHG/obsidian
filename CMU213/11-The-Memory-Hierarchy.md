# RAM
- Random-Access Memory，RAM通常被封装为一个芯片(chip)
- 基本存储单元是cell（每个cell存储1 bit）
- 多个RAM chip组成memory
- RAM分两种：SRAM(Static RAM)、DRAM(Dynamic RAM)
	![[Pasted image 20220417181908.png]]
	- Trans per bit：每bit需要晶体管
	- DRAM需要不断刷新，如果不施加电压，就会失去电荷，而SRAM插入并充电后，不需要刷新
	- SRAM比DRAM可靠得多，因此不需要进行错误检测和纠正（EDC），由于这种差异，SRAM比DRAM计算成本会更小、更快
# Nonvolatile Memories
ROM(Read-only memory)最初设定是出厂时候设定数据后就不能修改了。随着技术的发展，出现了Flash memory(EEPROM)，提供了block-level数据擦除功能，缺点是大约十万次擦除后就会磨损。
# CPU and Memory
内存使用一种称之为总线(bus)的电线连接到CPU，数据在电线上流动。
内存操作读取和写入通常可能是50纳秒到100纳秒而寄存器之间发生的操作是亚纳秒（subnanosecond）
![[Pasted image 20220418212908.png]]
## Memory Read Transaction
`Load operation: movq A, %rax`，将地址A处的8 bytes放到%rax
1. CPU places address A on the memory bus.
   ![[Pasted image 20220418213242.png]]
2. Main memory reads A from the memory bus, retrieves word x, and places it on the bus.
   ![[Pasted image 20220418213754.png]]
3. CPU read word x from the bus and copies it into register %rax.
   ![[Pasted image 20220418213911.png]]
## Memory Write Transaction
1. CPU places address A on bus. Main memory reads it and waits for the corresponding data word to arrive.
   ![[Pasted image 20220418214119.png]]
2. CPU places data word y on the bus.
   ![[Pasted image 20220418214149.png]]
3. Main memory reads data word y from the bus and stores it at address A.
![[Pasted image 20220418214217.png]]
# Disk
- SRAM access time is about  4 ns/doubleword, DRAM about  60 ns
	- Disk is about 40000 times slower than SRAM,  2500 times slower then DRAM.
- 磁盘呈现给CPU的是逻辑块0,1,2,...（Logical Disk Blocks），每一块都是扇区大小的倍数，磁盘控制器（disk controller）维护逻辑块和实际物理扇区之间的映射。
  ![[Pasted image 20220418221050.png]]
## Reading a Disk Sector 
1. CPU通过将command、logical block number和destination memory address（将数据放在内存的地址）写入与磁盘控制器相关联的端口(地址)来启动磁盘读取。
	![[Pasted image 20220418222047.png]]
2. 磁盘控制器将数据通过l/O bridge经由l/O总线直接复制到主内存（main memory），而无需通知 CPU
   ![[Pasted image 20220418222350.png]]
3. 当DMA传输完成时，磁盘控制器用中断通知CPU
   ![[Pasted image 20220418222552.png]]
4. 如果某处有某个程序在等待将该数据读入内存，那么现在CPU可以执行该程序并处理该内存
# Solid State Disks (SSDs)
![[Pasted image 20220418223312.png]]
- SSD中的Flash translation layer扮演磁盘控制器的角色
- 以页（page）为单位读取数据，页只有在块（Block）擦除（erase）后才能写入