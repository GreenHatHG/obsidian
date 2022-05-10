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

## 9.3 VM as a Tool for Caching

Conceptually, a virtual memory is organized as an array of N contiguous byte-size cells stored on disk. Each byte has a unique virtual address that serves as an index into the array. The contents of the array on disk are cached in main memory. As with any other cache in the memory hierarchy, the data on disk (the lower level) is partitioned into blocks that serve as the transfer units between the disk and the main memory (the upper level). VM systems handle this by partitioning the virtual memory into fixed-size blocks called virtual pages (VPs). Each virtual page is P = 2 bytes in size. Similarly, physical memory is partitioned into physical pages (PPs), also P bytes in size. (Physical pages are also referred to as page frames.)

从概念上讲，虚拟内存被组织为存储在磁盘上的 N 个连续字节大小单元的数组。每个字节都有一个唯一的虚拟地址，用作数组的索引。磁盘上数组的内容缓存在主内存中。与内存层次结构中的任何其他缓存一样，磁盘（较低级别）上的数据被划分为块，这些块用作磁盘和主内存（较高级别）之间的传输单元。 VM 系统通过将虚拟内存划分为称为虚拟页面 (VP) 的固定大小块来处理此问题。每个虚拟页面的大小为 P = 2 字节。类似地，物理内存被划分为物理页面 (PP)，大小也是 P 字节。 （物理页面也称为页框。）

At any point in time, the set of virtual pages is partitioned into three disjoint subsets:

在任何时间点，虚拟页面集都被划分为三个不相交的子集：

Unallocated. Pages that have not yet been allocated (or created) by the VM system. Unallocated blocks do not have any data associated with them, and thus do not occupy any space on disk.

未分配。 VM 系统尚未分配（或创建）的页面。未分配的块没有与它们关联的任何数据，因此不会占用磁盘上的任何空间。

Cached. Allocated pages that are currently cached in physical memory.

缓存。当前缓存在物理内存中的已分配页面。

Uncached. Allocated pages that are not cached in physical memory.

未缓存。未缓存在物理内存中的已分配页面。

The example in Figure 9.3 shows a small virtual memory with eight virtual pages. Virtual pages 0 and 3 have not been allocated yet, and thus do not yet exist on disk. Virtual pages 1,4, and 6 are cached in physical memory. Pages 2,5, and 7 are allocated but are not currently cached in physical memory.

图 9.3 中的示例显示了一个带有 8 个虚拟页面的小型虚拟内存。虚拟页面 0 和 3 尚未分配，因此尚不存在磁盘上。虚拟页面 1、4 和 6 缓存在物理内存中。第 2、5 和 7 页已分配，但当前未缓存在物理内存中。

### 9.3.1 DRAM Cache Organization

To help us keep the different caches in the memory hierarchy straight, we will use the term SRAM cache to denote the L1, L2, and L3 cache memories between the CPU and main memory, and the term DRAM cache to denote the VM system's cache that caches virtual pages in main memory.

为了帮助我们保持内存层次结构中的不同缓存，我们将使用术语SRAM cache来表示CPU和主存之间的一级、二级和三级缓存，使用术语DRAM cache来表示在主存中缓存虚拟页面的VM系统缓存。

The position of the DRAM cache in the memory hierarchy has a big impact on the way that it is organized. Recall that a DRAM is at least 10 times slower than an SRAM and that disk is about 100,000 times slower than a DRAM. Thus, misses in DRAM caches are very expensive compared to misses in SRAM caches because DRAM cache misses are served from disk, while SRAM cache misses are usually served from DRAM-based main memory. Further, the cost of reading the first byte from a disk sector is about 100,000 times slower than reading successive bytes in the sector. The bottom line is that the organization of the DRAM cache is driven entirely by the enormous cost of misses.

DRAM缓存在内存层次结构中的位置对其组织方式有很大影响。回想一下，DRAM的速度至少是SRAM的10倍，而磁盘的速度大约是DRAM的10万倍。因此，与SRAM缓存中的未命中相比，DRAM缓存中的未命中非常昂贵，因为DRAM缓存未命中是从磁盘提供的，而SRAM缓存未命中通常是从基于DRAM的主内存提供的。此外，从磁盘扇区读取第一个字节的成本大约是读取扇区中连续字节的100000倍。归根结底，DRAM缓存的组织完全是由巨大的未命中成本驱动的。

Because of the large miss penalty and the expense of accessing the first byte, virtual pages tend to be large—typically 4 KB to 2 MB. Due to the large miss penalty, DRAM caches are fully associative; that is, any virtual page can be placed in any physical page. The replacement policy on misses also assumes greater importance, because the penalty associated with replacing the wrong virtual page is so high. Thus, operating systems use much more sophisticated replacement algorithms for DRAM caches than the hardware does for SRAM caches. (These replacement algorithms are beyond our scope here.) Finally, because of the large access time of disk, DRAM caches always use write-back instead of write-through.

由于大量的未命中惩罚和访问第一个字节的开销，虚拟页面往往很大，通常为4KB到2MB。由于较大的未命中惩罚，DRAM缓存是完全关联的；也就是说，任何虚拟页面都可以放置在任何物理页面中。关于未命中的替换策略也具有更大的重要性，因为替换错误的虚拟页面的代价非常高。因此，操作系统使用的DRAM缓存替换算法比硬件使用的SRAM缓存替换算法复杂得多。（这些替换算法超出了我们的范围。）最后，由于磁盘的访问时间较长，DRAM缓存总是使用回写而不是直写。

### 9.3.2 Page Tables

As with any cache, the VM system must have some way to determine if a virtual page is cached somewhere in DRAM. If so, the system must determine which physical page it is cached in. If there is a miss, the system must determine where the virtual page is stored on disk, select a victim page in physical memory, and copy the virtual page from disk to DRAM, replacing the victim page.

与任何缓存一样，VM系统必须有某种方法来确定是否将虚拟页缓存在DRAM中的某处。如果是，系统必须确定它缓存在哪个物理页中。如果出现错误，系统必须确定虚拟页存储在磁盘上的位置，在物理内存中选择一个受害者页，然后将虚拟页从磁盘复制到DRAM中，替换受害者页。

These capabilities are provided by a combination of operating system software, address translation hardware in the MMU (memory management unit), and a data structure stored in physical memory known as a page table that maps virtual pages to physical pages. The address translation hardware reads the page table each time it converts a virtual address to a physical address. The operating system is responsible for maintaining the contents of the page table and transferring pages back and forth between disk and DRAM.

这些功能是由操作系统软件、MMU(内存管理单元)中的地址转换硬件和存储在物理内存中的数据结构(称为将虚拟页面映射到物理页面的页表)组合提供的。地址转换硬件每次将虚拟地址转换为物理地址时都要读取页表。操作系统负责维护页表的内容，并在磁盘和DRAM之间来回传输页。

Figure 9.4 shows the basic organization of a page table. A page table is an array of page table entries (PTEs). Each page in the virtual address space has a PTE at a fixed offset in the page table. For our purposes, we will assume that each PTE consists of a valid bit and an n-bit address field. The valid bit indicates whether the virtual page is currently cached in DRAM. If the valid bit is set, the address field indicates the start of the corresponding physical page in DRAM where the virtual page is cached. If the valid bit is not set, then a null address indicates that the virtual page has not yet been allocated. Otherwise, the address points to the start of the virtual page on disk.

图9.4显示了页表的基本组织。页表是一个页表项(pte)数组。虚拟地址空间中的每个页在页表的固定偏移位置上都有一个PTE。出于我们的目的，我们将假设每个PTE由一个有效位和一个n位地址字段组成。有效位指示当前是否将虚拟页缓存在DRAM中。如果设置了有效位，则address字段表示缓存虚拟页的DRAM中相应物理页的起始位置。如果未设置有效位，则null地址表示尚未分配虚拟页。否则，地址指向磁盘上虚拟页的开始。

The example in Figure 9.4 shows a page table for a system with eight virtual pages and four physical pages. Four virtual pages (VP 1, VP 2, VP 4, and VP 7) are currently cached in DRAM. Two pages (VP 0 and VP 5) have not yet been allocated, and the rest (VP 3 and VP 6) have been allocated but are not currently cached. An important point to notice about Figure 9.4 is that because the DRAM cache is fully associative, any physical page can contain any virtual page.

图9.4中的示例显示了一个具有8个虚拟页面和4个物理页面的系统的页面表。四个虚拟页(vp1、vp2、vp4和vp7)目前缓存在DRAM中。有两个页面(VP 0和VP 5)还没有被分配，其余的(VP 3和VP 6)已经分配，但是目前没有被缓存。关于图9.4需要注意的重要一点是，由于DRAM缓存是完全关联的，任何物理页都可以包含任何虚拟页。

### 9.3.3 Page Hits

Consider what happens when the CPU reads a word of virtual memory contained in VP 2, which is cached in DRAM (Figure 9.5 ). Using a technique we will describe in detail in Section 9.6 , the address translation hardware uses the virtual address as an index to locate PTE 2 and read it from memory. Since the valid bit is set, the address translation hardware knows that VP 2 is cached in memory. So it uses the physical memory address in the PTE (which points to the start of the cached page in PP 1) to construct the physical address of the word.

考虑一下当CPU读取VP2中包含的虚拟内存的一个字时会发生什么，该虚拟内存缓存在DRAM中(图9.5)。使用我们将在第9.6节中详细描述的技术，地址转换硬件使用虚拟地址作为索引来定位PTE 2并从存储器中读取它。由于设置了有效位，因此地址转换硬件知道VP 2被高速缓存在存储器中。因此，它使用PTE中的物理内存地址(指向PP 1中缓存页面的开始)来构造字的物理地址。

### 9.3.4 Page Faults

In virtual memory parlance, a DRAM cache miss is known as a page fault. Figure 9.6 shows the state of our example page table before p the fault. The CPU has referenced a word in VP 3, which is not cached in DRAM. The address translation hardware reads PTE 3 from memory, infers from the valid bit that VP 3 is not cached, and triggers a page fault exception. The page fault exception invokes a page fault exception handler in the kernel, which selects a victim page—in this case, VP 4 stored in PP 3. If VP 4 has been modified, then the kernel copies it back to disk. In either case, the kernel modifies the page table entry for VP 4 to reflect the fact that VP 4 is no longer cached in main memory.

在虚拟内存术语中，DRAM缓存未命中称为页面错误。图9.6显示了我们的示例页表在p故障之前的状态。CPU在VP 3中引用了一个词，该词未缓存在DRAM中。地址转换硬件从存储器中读取PTE 3，从有效位推断VP 3未被高速缓存，并触发页面错误异常。页面错误异常调用内核中的页面错误异常处理程序，该处理程序选择一个牺牲页-在本例中，是存储在PP 3中的VP 4。如果VP 4已被修改，则内核会将其复制回磁盘。在这两种情况下，内核都会修改VP4的页表条目，以反映VP4不再缓存在主内存中的事实。

Next, the kernel copies VP 3 from disk to PP 3 in memory, updates PTE 3, and then returns. When the handler returns, it restarts the faulting instruction, which resends the faulting virtual address to the address translation hardware. But now, VP 3 is cached in main memory, and the page hit is handled normally by the address translation hardware. Figure 9.7 shows the state of our example page table after the page fault.

接下来，内核将 VP 3 从磁盘复制到内存中的 PP 3，更新 PTE 3，然后返回。当处理程序返回时，它重新启动出错指令，将出错的虚拟地址重新发送到地址转换硬件。但是现在，VP 3 缓存在主存中，页面命中由地址转换硬件正常处理。图 9.7 显示了页面错误后示例页表的状态。

Virtual memory was invented in the early 1960s, long before the widening CPU-memory gap spawned SRAM caches. As a result, virtual memory systems use a different terminology from SRAM caches, even though many of the ideas are similar. In virtual memory parlance, blocks are known as pages. The activity of transferring a page between disk and memory is known as swapping or paging. Pages are swapped in (paged in) from disk to DRAM, and swapped out (paged out) from DRAM to disk. The strategy of waiting until the last moment to swap in a page, when a miss occurs, is known as demand paging. Other approaches, such as trying to predict misses and swap pages in before they are actually referenced, are possible. However, all modern systems use demand paging.

虚拟内存是在 1960 年代初发明的，早在 CPU 内存差距扩大催生 SRAM 缓存之前。因此，虚拟内存系统使用与 SRAM 缓存不同的术语，尽管许多想法是相似的。在虚拟内存用语中，块被称为页。在磁盘和内存之间传输页面的活动称为交换或分页。页面从磁盘换入（paged in）到 DRAM，并从 DRAM 换出（paged out）到磁盘。当发生未命中时，等到最后一刻换入页面的策略称为请求分页。其他方法，例如在实际引用之前尝试预测未命中和交换页面，也是可能的。然而，所有现代系统都使用按需寻呼。

### 9.3.5 Allocating Pages

Figure 9.8 shows the effect on our example page table when the operating system allocates a new page of virtual memory—for example, as a result of calling malloc . In the example, VP 5 is allocated by creating room on disk and updating PTE 5 to point to the newly created page on disk.

图9.8显示了当操作系统分配一个新的虚拟内存页面时对我们的示例页表的影响--例如，作为调用Malloc的结果。在本例中，通过在磁盘上创建空间并更新PTE5以指向磁盘上新创建的页面来分配VP5。

### 9.3.6 Locality to the Rescue Again

When many of us learn about the idea of virtual memory, our first impression is often that it must be terribly inefficient. Given the large miss penalties, we worry that paging will destroy program performance. In practice, virtual memory works well, mainly because of our old friend locality.

当我们中的许多人了解虚拟内存的概念时，我们的第一印象往往是它一定非常低效。考虑到大量的未命中惩罚，我们担心分页会破坏程序性能。在实践中，虚拟内存运行良好，主要是因为我们的老朋友 locality。

Although the total number of distinct pages that programs reference during an entire run might exceed the total size of physical memory, the principle of locality promises that at any point in time they will tend to work on a smaller set of active pages known as the working set or resident set. After an initial overhead where the working set is paged into memory, subsequent references to the working set result in hits, with no additional disk traffic.

尽管程序在整个运行期间引用的不同页面的总数可能会超过物理内存的总大小，但局部性原则承诺，在任何时间点，它们都将倾向于在称为工作集或驻留集的较小的活动页面集上工作。在将工作集分页到内存的初始开销之后，对工作集的后续引用将导致命中，而不会产生额外的磁盘流量。

As long as our programs have good temporal locality, virtual memory systems work quite well. But of course, not all programs exhibit good temporal locality. If the working set size exceeds the size of physical memory, then the program can produce an unfortunate situation known as thrashing, where pages are swapped in and out continuously. Although virtual memory is usually efficient, if a program's performance slows to a crawl, the wise programmer will consider the possibility that it is thrashing.

只要我们的程序具有良好的时间局部性，虚拟内存系统就可以很好地工作。但当然，并不是所有的程序都表现出良好的时间局部性。如果工作集大小超过了物理内存的大小，那么程序可能会产生一种称为颠簸的不幸情况，即不断地换入和换出页面。虽然虚拟内存通常是高效的，但如果程序的性能下降到爬行的程度，明智的程序员会考虑到它正在抖动的可能性。

### 9.4 VM as a Tool for Memory Management

In the last section, we saw how virtual memory provides a mechanism for using the DRAM to cache pages from a typically larger virtual address space. Interestingly, some early systems such as the DEC PDP-11/70 supported a virtual address space that was smaller than the available physical memory. Yet virtual memory was still a useful mechanism because it greatly simplified memory management and provided a natural way to protect memory.

在上一节中，我们了解了虚拟内存如何提供一种使用DRAM从通常较大的虚拟地址空间缓存页面的机制。有趣的是，一些早期的系统，如DEC PDP-11/70，支持小于可用物理内存的虚拟地址空间。然而，虚拟内存仍然是一种有用的机制，因为它大大简化了内存管理，并提供了一种自然的方式来保护内存。

Thus far, we have assumed a single page table that maps a single virtual address space to the physical address space. In fact, operating systems provide a separate page table, and thus a separate virtual address space, for each process. Figure 9.9 shows the basic idea. In the example, the page table for process i maps VP 1 to PP 2 and VP 2 to PP 7. Similarly, the page table for process j maps VP 1 to PP 7 and VP 2 to PP 10. Notice that multiple virtual pages can be mapped to the same shared physical page.

到目前为止，我们假设了一个将单个虚拟地址空间映射到物理地址空间的单页表。事实上，操作系统为每个进程提供了单独的页表，因此也提供了单独的虚拟地址空间。图9.9显示了基本思想。在本例中，进程i的页表将VP 1映射到PP 2，VP 2映射到PP 7。类似地，进程j的页表将VP 1映射到PP 7，VP 2映射到PP 10。请注意，多个虚拟页可以映射到同一共享物理页。

The combination of demand paging and separate virtual address spaces has a profound impact on the way that memory is used and managed in a system. In particular, VM simplifies linking and loading, the sharing of code and data, and allocating memory to applications.

请求分页和单独的虚拟地址空间的组合对系统中内存的使用和管理方式产生了深远的影响。特别是，VM简化了链接和加载、代码和数据的共享以及为应用程序分配内存。

Simplifying linking. A separate address space allows each process to use the same basic format for its memory image, regardless of where the code and data actually reside in physical memory. For example, as we saw in Figure 8.13 , every process on a given Linux system has a similar memory format. For 64-bit address spaces, the code segment always starts at virtual address 0x400000 . The data segment follows the code segment after a suitable alignment gap. The stack occupies the highest portion of the user process address space and grows downward. Such uniformity greatly simplifies the design and implementation of linkers, allowing them to produce fully linked executables that are independent of the ultimate location of the code and data in physical memory.

简化链接。一个独立的地址空间允许每个进程对其内存映像使用相同的基本格式，而不管代码和数据在物理内存中实际位于何处。例如，正如我们在图8.13中看到的，在一个给定的Linux系统上的每个进程都有类似的内存格式。对于64位地址空间，代码段总是从虚拟地址0x400000开始。数据段在一个合适的对齐间隙后紧随代码段。堆栈占据了用户进程地址空间的最高部分并向下增长。这种统一性大大简化了链接器的设计和实现，使它们能够产生完全链接的可执行文件，而这些文件与物理内存中的代码和数据的最终位置无关。

Simplifying loading. Virtual memory also makes it easy to load executable and shared object files into memory. To load the .text and .data sections of an object file into a newly created process, the Linux loader allocates virtual pages for the code and data segments, marks them as invalid (i.e., not cached), and points their page table entries to the appropriate locations in the object file. The interesting point is that the loader never actually copies any data from disk into memory. The data are paged in automatically and on demand by the virtual memory system the first time each page is referenced, either by the CPU when it fetches an instruction or by an executing instruction when it references a memory location.

简化装载。虚拟内存还可以轻松地将可执行文件和共享对象文件加载到内存中。来加载。文本和文本。在新创建的进程中，Linux加载程序为代码和数据段分配虚拟页面，将它们标记为无效（即未缓存），并将它们的页面表条目指向对象文件中的适当位置。有趣的是，加载程序从未将任何数据从磁盘复制到内存中。当每个页面第一次被引用时，数据会被虚拟内存系统自动按需分页，无论是由CPU在获取指令时，还是由执行指令在引用内存位置时。

This notion of mapping a set of contiguous virtual pages to an arbitrary location in an arbitrary file is known as memory mapping. Linux provides a system call called mmap that allows application programs to do their own memory mapping. We will describe application-level memory mapping in more detail in Section 9.8 .

将一组连续的虚拟页映射到任意文件中的任意位置的概念称为内存映射。Linux提供了一个名为mmap的系统调用，允许应用程序自己进行内存映射。我们将在第9.8节中更详细地描述应用程序级内存映射。

Simplifying sharing. Separate address spaces provide the operating system with a consistent mechanism for managing sharing between user processes and the operating system itself. In general, each process has its own private code, data, heap, and stack areas that are not shared with any other process. In this case, the operating system creates page tables that map the corresponding virtual pages to disjoint physical pages.

简化共享。单独的地址空间为操作系统提供了一致的机制，用于管理用户进程和操作系统本身之间的共享。通常，每个进程都有自己的私有代码、数据、堆和堆栈区域，这些区域不与任何其他进程共享。在这种情况下，操作系统会创建页表，将相应的虚拟页映射到不相交的物理页。

However, in some instances it is desirable for processes to share code and data. For example, every process must call the same operating system kernel code, and every C program makes calls to routines in the standard C library such as printf . Rather than including separate copies of the kernel and standard C library in each process, the operating system can arrange for multiple processes to share a single copy of this code by mapping the appropriate virtual pages in different processes to the same physical pages, as we saw in Figure 9.9 .

然而，在某些情况下，希望进程共享代码和数据。例如，每个进程必须调用相同的操作系统内核代码，并且每个C程序都调用标准C库中的例程，如printf。操作系统可以通过将不同进程中的适当虚拟页映射到相同的物理页来安排多个进程共享该代码的单个副本，而不是在每个进程中包括内核和标准C库的单独副本，如图9.9所示。

Simplifying memory allocation. Virtual memory provides a simple mechanism for allocating additional memory to user processes. When a program running in a user process requests additional heap space (e.g., as a result of calling malloc ), the operating system allocates an appropriate number, say, k, of contiguous virtual memory pages, and maps them to k arbitrary physical pages located anywhere in physical memory. Because of the way page tables work, there is no need for the operating system to locate k contiguous pages of physical memory. The pages can be scattered randomly in physical memory.

简化内存分配。虚拟内存提供了一种向用户进程分配额外内存的简单机制。当运行在用户进程中的程序请求额外的堆空间(例如，由于调用malloc)时，操作系统分配适当的数量，例如k，连续的虚拟内存页，并将它们映射到物理内存中任意位置的k个物理页。由于页表的工作方式，操作系统不需要定位物理内存中的k个连续页。页面可以随机地分散在物理内存中。

### 9.5 VM as a Tool for Memory Protection

Any modern computer system must provide the means for the operating system to control access to the memory system. A user process should not be allowed to modify its read-only code section. Nor should it be allowed to read or modify any of the code and data structures in the kernel. It should not be allowed to read or write the private memory of other processes, and it should not be allowed to modify any virtual pages that are shared with other processes, unless all parties explicitly allow it (via calls to explicit interprocess communication system calls).

任何现代计算机系统都必须为操作系统提供控制访问内存系统的手段。一个用户进程不应该被允许修改其只读的代码部分。也不应该允许它读取或修改内核中的任何代码和数据结构。它不应该被允许读写其他进程的私有内存，也不应该被允许修改任何与其他进程共享的虚拟页，除非各方都明确允许（通过调用明确的进程间通信系统调用）。

As we have seen, providing separate virtual address spaces makes it easy to isolate the private memories of different processes. But the address translation mechanism can be extended in a natural way to provide even finer access control. Since the address translation hardware reads a PTE each time the CPU generates an address, it is straightforward to control access to the contents of a virtual page by adding some additional permission bits to the PTE. Figure 9.10 shows the general idea.

正如我们所见，提供单独的虚拟地址空间可以很容易地隔离不同进程的私有内存。但是地址转换机制可以以一种自然的方式进行扩展，以提供更精细的访问控制。由于每次 CPU 生成地址时地址转换硬件都会读取 PTE，因此可以直接通过向 PTE 添加一些额外的权限位来控制对虚拟页面内容的访问。图 9.10 显示了总体思路。

In this example, we have added three permission bits to each PTE. The SUP bit indicates whether processes must be running in kernel (supervisor) mode to access the page. Processes running in kernel mode can access any page, but processes running in user mode are only allowed to access pages for which SUP is 0. The READ and WRITE bits control read and write access to the page. For example, if process i is running in user mode, then it has permission to read VP 0 and to read or write VP 1. However, it is not allowed to access VP 2.

在此示例中，我们为每个 PTE 添加了三个权限位。 SUP 位指示进程是否必须在内核（主管）模式下运行才能访问页面。在内核模式下运行的进程可以访问任何页面，但在用户模式下运行的进程只允许访问 SUP 为 0 的页面。READ 和 WRITE 位控制对页面的读写访问。例如，如果进程 i 在用户模式下运行，则它有权读取 VP 0 和读取或写入 VP 1。但是，它不允许访问 VP 2。

If an instruction violates these permissions, then the CPU triggers a general protection fault that transfers control to an exception handler in the kernel, which sends a SIGSEGV signal to the offending process. Linux shells typically report this exception as a "segmentation fault."

如果一条指令违反了这些权限，那么 CPU 会触发一个通用保护错误，将控制权转移到内核中的异常处理程序，该处理程序向有问题的进程发送一个 SIGSEGV 信号。 Linux shell 通常将此异常报告为“分段错误”。

## 9.6 Address Translation

This section covers the basics of address translation. Our aim is to give you an appreciation of the hardware's role in supporting virtual memory, with enough detail so that you can work through some concrete examples by hand. However, keep in mind that we are omitting a number of details, especially related to timing,

本节介绍地址翻译的基础知识。我们的目标是让您了解硬件在支持虚拟内存方面的作用，并提供足够的详细信息，以便您可以手动完成一些具体的示例。但是，请记住，我们忽略了一些细节，尤其是与时间有关的细节，

Formally, address translation is a mapping between the elements of an N-element virtual address space (VAS) and an M-element physical address space (PAS),

从形式上讲，地址转换是N元素虚拟地址空间（VAS）和M元素物理地址空间（PAS）元素之间的映射，

Figure 9.12 shows how the MMU uses the page table to perform this mapping. A control register in the CPU, the page table base register (PTBR) points to the current page table. The n-bit virtual address has two components: a p-bit virtual page offset (VPO) and an (n -- p)-bit virtual page number (VPN). The MMU uses the VPN to select the appropriate PTE. For example, VPN 0 selects PTE 0, VPN 1 selects PTE 1, and so on. The corresponding physical address is the concatenation of the physical page number (PPN) from the page table entry and the VPO from the virtual address. Notice that since the physical and virtual pages are both P bytes, the physical page offset (PPO) is identical to the VPO.

图 9.12 显示了 MMU 如何使用页表来执行此映射。 CPU中的一个控制寄存器，页表基址寄存器（PTBR）指向当前页表。 n 位虚拟地址有两个组成部分：一个 p 位虚拟页偏移量 (VPO) 和一个 (n -- p) 位虚拟页号 (VPN)。 MMU 使用 VPN 来选择合适的 PTE。例如，VPN 0 选择 PTE 0，VPN 1 选择 PTE 1，依此类推。对应的物理地址是来自页表条目的物理页号 (PPN) 和来自虚拟地址的 VPO 的串联。请注意，由于物理页和虚拟页都是 P 字节，因此物理页偏移 (PPO) 与 VPO 相同。

Figure 9.13(a) shows the steps that the CPU hardware performs when there is a page hit. Step 1. The processor generates a virtual address and sends it to the MMU. Step 2. The MMU generates the PTE address and requests it from the cache/main memory. Step 3. The cache/main memory returns the PTE to the MMU. Step 4. The MMU constructs the physical address and sends it to the cache/main memory. Step 5. The cache/main memory returns the requested data word to the processor.

图 9.13(a) 显示了当页面命中时 CPU 硬件执行的步骤。步骤 1. 处理器生成一个虚拟地址并将其发送给 MMU。步骤 2. MMU 生成 PTE 地址并从缓存/主存储器请求它。步骤 3. 高速缓存/主存储器将 PTE 返回给 MMU。步骤 4. MMU 构造物理地址并将其发送到缓存/主存储器。步骤 5. 高速缓存/主存储器将请求的数据字返回给处理器。

Unlike a page hit, which is handled entirely by hardware, handling a page fault requires cooperation between hardware and the operating system kernel (Figure 9.13(b) ).

与完全由硬件处理的页面命中不同，处理页面错误需要硬件和操作系统内核之间的合作（图9.13（b））。

Steps 1 to 3. The same as steps 1 to 3 in Figure 9.13(a) . Step 4. The valid bit in the PTE is zero, so the MMU triggers an exception, which transfers control in the CPU to a page fault exception handler in the operating system kernel. Step 5. The fault handler identifies a victim page in physical memory, and if that page has been modified, pages it out to disk. Step 6. The fault handler pages in the new page and updates the PTE in memory. Step 7. The fault handler returns to the original process, causing the faulting instruction to be restarted. The CPU resends the offending virtual address to the MMU. Because the virtual page is now cached in physical memory, there is a hit, and after the MMU performs the steps in Figure 9.13(a) , the main memory returns the requested word to the processor.

步骤 1 至 3。与图 9.13(a) 中的步骤 1 至 3 相同。步骤 4. PTE 中的有效位为零，因此 MMU 触发异常，将 CPU 中的控制权转移到操作系统内核中的缺页异常处理程序。第 5 步：故障处理程序识别物理内存中的受害者页面，如果该页面已被修改，则将其分页到磁盘。步骤 6. 故障处理程序在新页面中分页并更新内存中的 PTE。步骤 7. 故障处理程序返回原来的进程，导致故障指令重新启动。 CPU 将有问题的虚拟地址重新发送到 MMU。因为虚拟页面现在缓存在物理内存中，所以有一个命中，在 MMU 执行图 9.13(a) 中的步骤之后，主内存将请求的字返回给处理器。

