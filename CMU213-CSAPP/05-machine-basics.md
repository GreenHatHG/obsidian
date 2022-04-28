# Machine basics

## Intel x86 Processors

- x86只是口头描述，因为intel推出8086处理器后，接着推出了8286，8386等处理器，都带一个86，所以称为x86。

- x86有时候被称为CISC(Complex instruction set computer)，与RISC(Reduced Instruction Set Computers)相对，具体许多不同格式的指令，但是Linux程序只用到一小部分。

### Intel x86 Evolution: Milestones

![png](05-machine-basics/2022-04-28_154125.png)

- 1985年的386，扩展到了32位，真正实现可以实际运行Linux/Unix，移除一些奇怪的指令，让其更加通用。也称IA32(Intel architecture 32)，基于这种指令集架构的编码方式持续了很多年。

- 2004年之前，为了加快CPU运行速度，CPU频率一直增大，直到遇到芯片功耗问题。所以不再提高单核处理器CPU频率，而是采用多核的方式。这些核心彼此间是独立的，它们共同位于同一个芯片内。

