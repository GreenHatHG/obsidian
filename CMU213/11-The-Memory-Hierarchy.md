# RAM
- Random-Access Memory，RAM通常被封装为一个芯片(chip)
- 基本存储单元是cell（每个cell存储1 bit）
- 多个RAM chip组成memory
- RAM分两种：SRAM(Static RAM)、DRAM(Dynamic RAM)
	![[Pasted image 20220417181908.png]]
	- Trans per bit：每bit需要晶体管
	- DRAM需要不断刷新，如果不施加电压，就会失去电荷，而SRAM插入并充电后，不需要刷新
	- SRAM比DRAM可靠得多，因此不需要进行错误检测和纠正（EDC），由于这种差异，SRAM比DRAM计算成本会更小、更快
