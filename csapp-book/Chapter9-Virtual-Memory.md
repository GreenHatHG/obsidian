# Chapter9-Virtual-Memory

Processes in a system share the CPU and main memory with other processes. However, sharing the main memory poses some special challenges. As demand on the CPU increases, processes slow down in some reasonably smooth way. But if too many processes need too much memory, then some of them will simply not be able to run. When a program is out of space, it is out of luck. Memory is also vulnerable to corruption. If some process inadvertently writes to the memory used by another process, that process might fail in some bewildering fashion totally unrelated to the program logic.

系统中的进程与其他进程共享CPU和主存。然而，共享主内存带来了一些特殊的挑战。随着对CPU的需求增加，进程会以某种相当平滑的方式变慢。但是，如果太多进程需要太多内存，那么其中一些进程将无法运行。当一个程序超出空间时，它就是运气不好。记忆也容易腐败。如果某个进程无意中写入了另一个进程使用的内存，该进程可能会以某种与程序逻辑完全无关的令人困惑的方式失败。

In order to manage memory more efficiently and with fewer errors, modern systems provide an abstraction of main memory known as virtual memory (VM). Virtual memory is an elegant interaction of hardware exceptions, hardware address translation, main memory, disk files, and kernel software that provides each process with a large, uniform, and private address space. With one clean mechanism, virtual memory provides three important capabilities: (1) It uses main memory efficiently by treating it as a cache for an address space stored on disk, keeping only the active areas in main memory and transferring data back and forth between disk and memory as needed. (2) It simplifies memory management by providing each process with a uniform address space. (3) It protects the address space of each process from corruption by other processes.

为了更有效地管理内存并减少错误，现代系统提供了一种主存的抽象，称为虚拟内存(VM)。虚拟内存是硬件异常、硬件地址转换、主存、磁盘文件和内核软件的优雅交互，为每个进程提供了一个大的、统一的、私有的地址空间。通过一种干净的机制，虚拟内存提供了三个重要的功能:(1)它有效地利用主存，将主存作为存储在磁盘上的地址空间的缓存，只保留主存中的活动区域，并根据需要在磁盘和内存之间来回传输数据。(2)为每个进程提供统一的地址空间，简化了内存管理。(3)保护每个进程的地址空间不被其他进程破坏。

Virtual memory is one of the great ideas in computer systems. A major reason for its success is that it works silently and automatically, without any intervention from the application programmer. Since virtual memory works so well behind the scenes, why would a programmer need to understand it? There are several reasons.

虚拟存储器是计算机系统中最伟大的思想之一。它成功的一个主要原因是它以静默和自动的方式工作，不需要应用程序程序员的任何干预。既然虚拟内存在幕后工作得这么好，程序员为什么还要理解它呢?有几个原因。

Virtual memory is central. Virtual memory pervades all levels of computer systems, playing key roles in the design of hardware exceptions, assemblers, linkers, loaders, shared objects, files, and processes. Understanding virtual memory will help you better understand how systems work in general.

虚拟内存是中心。虚拟内存遍及各级计算机系统，在硬件异常、汇编器、链接器、加载器、共享对象、文件和进程的设计中发挥着关键作用。理解虚拟内存将帮助您更好地理解系统一般是如何工作的。

Virtual memory is powerful. Virtual memory gives applications powerful capabilities to create and destroy chunks of memory, map chunks of memory to portions of disk files, and share memory with other processes. For example, did you know that you can read or modify the contents of a disk file by reading and writing memory locations? Or that you can load the contents of a file into memory without doing any explicit copying? Understanding virtual memory will help you harness its powerful capabilities in your applications.

虚拟内存功能强大。虚拟内存为应用程序提供了强大的功能，可以创建和销毁内存块，将内存块映射到磁盘文件的各个部分，并与其他进程共享内存。例如，您知道可以通过读写内存位置来读取或修改磁盘文件的内容吗?或者您可以在不进行任何显式复制的情况下将文件的内容加载到内存中?理解虚拟内存将有助于您在应用程序中利用它的强大功能。

Virtual memory is dangerous. Applications interact with virtual memory every time they reference a variable, dereference a pointer, or make a call to a dynamic allocation package such as malloc . If virtual memory is used improperly, applications can suffer from perplexing and insidious memory-related bugs. For example, a program with a bad pointer can crash immediately with a "segmentation fault" or a "protection fault," run silently for hours before crashing, or scariest of all, run to completion with incorrect results. Understanding virtual memory, and the allocation packages such as malloc that manage it, can help you avoid these errors.

虚拟内存是危险的。应用程序每次引用变量、解引用指针或调用动态分配包(如malloc)时都与虚拟内存进行交互。如果虚拟内存使用不当，应用程序可能会遭受令人困惑和潜伏的内存相关bug。例如，一个带有错误指针的程序可能会因为“分割错误”或“保护错误”而立即崩溃，在崩溃之前可以安静地运行几个小时，或者最可怕的是，运行到结束时结果不正确。了解虚拟内存以及诸如管理它的malloc等分配包，可以帮助您避免这些错误。

This chapter looks at virtual memory from two angles. The first half of the chapter describes how virtual memory works. The second half describes how virtual memory is used and managed by applications. There is no avoiding the fact that VM is complicated, and the discussion reflects this in places. The good news is that if you work through the details, you will be able to simulate the virtual memory mechanism of a small system by hand, and the virtual memory idea will be forever demystified.

本章从两个角度来看虚拟内存。本章的前半部分描述了虚拟内存的工作原理。第二部分描述了应用程序如何使用和管理虚拟内存。无法避免的事实是，虚拟机是复杂的，讨论在某些地方反映了这一点。好消息是，如果你仔细研究细节，你将能够用手模拟一个小系统的虚拟内存机制，虚拟内存的概念将永远不再神秘。

The second half builds on this understanding, showing you how to use and manage virtual memory in your programs. You will learn how to manage virtual memory via explicit memory mapping and calls to dynamic storage allocators such as the malloc package. You will also learn about a host of common memory-related errors in C programs and how to avoid them.

下半部分基于这种理解，向您展示如何在程序中使用和管理虚拟内存。您将学习如何通过显式内存映射和调用动态存储分配器（如malloc包）来管理虚拟内存。您还将了解C程序中与内存有关的许多常见错误，以及如何避免这些错误。

## 9.1 Physical and Virtual Addressing

The main memory of a computer system is organized as an array of M contiguous byte-size cells. Each byte has a unique physical address (PA). The first byte has an address of 0, the next byte an address of 1, the next byte an address of 2, and so on. Given this simple organization, the most natural way for a CPU to access memory would be to use physical addresses. We call this approach physical addressing. Figure 9.1 shows an example of physical addressing in the context of a load instruction that reads the 4-byte word starting at physical address 4. When the CPU executes the load instruction, it generates an effective physical address and passes it to main memory over the memory bus. The main memory fetches the 4-byte word starting at physical address 4 and returns it to the CPU, which stores it in a register.

计算机系统的主存是由M个连续字节大小的单元组成的数组。每个字节都有一个唯一的物理地址（PA）。第一个字节的地址为0，下一个字节的地址为1，下一个字节的地址为2，依此类推。考虑到这种简单的组织，CPU访问内存的最自然的方式是使用物理地址。我们称这种方法为物理寻址。图9.1显示了加载指令中的物理寻址示例，加载指令读取从物理地址4开始的4字节字。当CPU执行load指令时，它会生成一个有效的物理地址，并通过内存总线将其传递给主存。主存储器获取从物理地址4开始的4字节字，并将其返回给CPU，CPU将其存储在寄存器中。

Early PCs used physical addressing, and systems such as digital signal processors, embedded microcontrollers, and Cray supercomputers continue to do so. However, modern processors use a form of addressing known as virtual addressing, as shown in Figure 9.2 .

早期的个人电脑使用物理寻址，数字信号处理器、嵌入式微控制器和克雷超级计算机等系统继续使用物理寻址。然而，现代处理器使用一种称为虚拟寻址的寻址形式，如图9.2所示。

With virtual addressing, the CPU accesses main memory by generating a virtual address (VA), which is converted to the appropriate physical address before being sent to main memory. The task of converting a virtual address to a physical one is known as address translation. Like exception handling, address translation requires close cooperation between the CPU hardware and the operating system. Dedicated hardware on the CPU chip called the memory management unit (MMU) translates virtual addresses on the fly, using a lookup table stored in main memory whose contents are managed by the operating system.

通过虚拟寻址，CPU通过生成虚拟地址（VA）来访问主存，虚拟地址在发送到主存之前被转换为适当的物理地址。将虚拟地址转换为物理地址的任务称为地址转换。与异常处理一样，地址转换需要CPU硬件和操作系统之间的密切合作。CPU芯片上名为内存管理单元（MMU）的专用硬件使用存储在主内存中的查找表实时转换虚拟地址，其内容由操作系统管理。

## 9.2 Address Spaces

An address space is an ordered set of nonnegative integer addresses

地址空间是一组有序的非负整数地址

{ 0, 1, 2, … }

If the integers in the address space are consecutive, then we say that it is a linear address space. To simplify our discussion, we will always assume linear address spaces. In a system with virtual memory, the CPU generates virtual addresses from an address space of N = 2 addresses called the virtual address space:

如果地址空间中的整数是连续的，那么我们称之为线性地址空间。为了简化我们的讨论，我们总是假设线性地址空间。在具有虚拟内存的系统中，CPU从N=2个地址的地址空间生成虚拟地址，称为虚拟地址空间：

{ 0, 1, 2, …, N−1 }

The size of an address space is characterized by the number of bits that are needed to represent the largest address. For example, a virtual address space with N = 2 addresses is called an n-bit address space. Modern systems typically support either 32-bit or 64-bit virtual address spaces. A system also has a physical address space that corresponds to the M bytes of physical memory in the system:

地址空间的大小由代表最大地址所需的位数来表示。例如，一个N = 2个地址的虚拟地址空间称为N位地址空间。现代系统通常支持32位或64位虚拟地址空间。系统也有一个物理地址空间，对应于系统中M字节的物理内存:

{ 0, 1, 2, …, M−1 }

M is not required to be a power of 2, but to simplify the discussion, we will assume that M = 2 .

M不一定是2的幂，但为了简化讨论，我们假设M = 2。

The concept of an address space is important because it makes a clean distinction between data objects (bytes) and their attributes (addresses). Once we recognize this distinction, then we can generalize and allow each data object to have multiple independent addresses, each chosen from a different address space. This is the basic idea of virtual memory. Each byte of main memory has a virtual address chosen from the virtual address space, and a physical address chosen from the physical address space.

地址空间的概念很重要，因为它明确区分了数据对象(字节)和它们的属性(地址)。一旦我们认识到这种区别，那么我们就可以一般化并允许每个数据对象有多个独立的地址，每个地址都是从不同的地址空间中选择的。这就是虚拟内存的基本思想。主存中的每个字节都有一个从虚拟地址空间中选择的虚拟地址和一个从物理地址空间中选择的物理地址。
