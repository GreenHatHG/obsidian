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
内存使用一种称之为bus（总线）的电线连接到CPU，数据在电线上流动。
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
- 磁盘呈现给CPU的是Logical Disk Blocks(0,1,2,...)，每一块都是扇区大小的倍数，disk controller维护逻辑块和实际物理扇区之间的映射。