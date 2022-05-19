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

### 9.6.1 Integrating Caches and VM

In any system that uses both virtual memory and SRAM caches, there is the issue of whether to use virtual or physical addresses to access the SRAM cache. Although a detailed discussion of the trade-offs is beyond our scope here, most systems opt for physical addressing. With physical addressing, it is straightforward for multiple processes to have blocks in the cache at the same time and to share blocks from the same virtual pages. Further, the cache does not have to deal with protection issues, because access rights are checked as part of the address translation process.

在同时使用虚拟内存和SRAM缓存的任何系统中，都存在使用虚拟地址还是物理地址来访问SRAM缓存的问题。虽然关于权衡的详细讨论超出了我们的讨论范围，但大多数系统都选择物理寻址。通过物理寻址，多个进程可以直接在缓存中同时拥有块，并共享来自同一虚拟页面的块。此外，缓存不必处理保护问题，因为访问权限是作为地址转换过程的一部分进行检查的。

Figure 9.14 shows how a physically addressed cache might be integrated with virtual memory. The main idea is that the address translation occurs before the cache lookup. Notice that page table entries can be cached, just like any other data words

图9.14显示了如何将物理寻址缓存与虚拟内存集成。其主要思想是地址转换在高速缓存查找之前进行。请注意，页表条目可以被缓存，就像任何其他数据字一样

### 9.6.2 Speeding Up Address Translation with a TLB

As we have seen, every time the CPU generates a virtual address, the MMU must refer to a PTE in order to translate the virtual address into a physical address. In the worst case, this requires an additional fetch from memory, at a cost of tens to hundreds of cycles. If the PTE happens to be cached in L1, then the cost goes down to a handful of cycles. However, many systems try to eliminate even this cost by including a small cache of PTEs in the MMU called a translation lookaside buffer (TLB).

正如我们所看到的，每次 CPU 生成一个虚拟地址时，MMU 必须引用一个 PTE 才能将虚拟地址转换为物理地址。在最坏的情况下，这需要从内存中进行额外的提取，代价是数十到数百个周期。如果 PTE 恰好缓存在 L1 中，那么成本会下降到几个周期。然而，许多系统试图通过在 MMU 中包含一个称为转换后备缓冲区 (TLB) 的小型 PTE 缓存来消除这种成本。

A TLB is a small, virtually addressed cache where each line holds a block consisting of a single PTE. A TLB usually has a high degree of associativity. As shown in Figure 9.15 , the index and tag fields that are used for set selection and line matching are extracted from the virtual page number in the virtual address. If the TLB has T = 2 sets, then the TLB index (TLBI) consists of the t least significant bits of the VPN, and the TLB tag (TLBT) consists of the remaining bits in the VPN.

TLB是一个小的、虚拟寻址的缓存，其中每一行保存一个由单个PTE组成的块，TLB通常具有高度的结合性。如图9.15所示，用于集选择和行匹配的索引和标记字段是从虚拟地址中的虚拟页码中提取的。如果TLB有T = 2个集合，则TLB索引(TLBI)由VPN的T个最低有效位组成，TLB标签(TLBT)由VPN中剩余的位组成。

Figure 9.16(a) shows the steps involved when there is a TLB hit (the usual case). The key point here is that all of the address translation steps are performed inside the on-chip MMU and thus are fast.  Step 1. The CPU generates a virtual address. Steps 2 and 3. The MMU fetches the appropriate PTE from the TLB. Step 4. The MMU translates the virtual address to a physical address and sends it to the cache/main memory. Step 5. The cache/main memory returns the requested data word to the CPU.

图9.16(A)显示了出现TLB命中时所涉及的步骤(通常情况下)。这里的关键点是，所有地址转换步骤都在片上MMU内执行，因此速度很快。步骤1.CPU生成虚拟地址。步骤2和3.MMU从TLB取回适当的PTE。步骤4.MMU将虚拟地址转换为物理地址，并将其发送到高速缓存/主存储器。步骤5.高速缓存/主存储器将所请求的数据字返回给CPU。

When there is a TLB miss, then the MMU must fetch the PTE from the L1 cache, as shown in Figure 9.16(b) . The newly fetched PTE is stored in the TLB, possibly overwriting an existing entry

当存在TLB未命中时，MMU必须从L1缓存获取PTE，如图9.16(B)所示。新获取的PTE存储在TLB中，可能覆盖现有条目

### 9.6.3 Multi-Level Page Tables

Thus far, we have assumed that the system uses a single page table to do address translation. But if we had a 32-bit address space, 4 KB pages, and a 4-byte PTE, then we would need a 4 MB page table resident in memory at all times, even if the application referenced only a small chunk of the virtual address space. The problem is compounded for systems with 64-bit address spaces.

到目前为止，我们假设系统使用单个页表来执行地址转换。但是，如果我们有一个32位的地址空间、4KB的页面和一个4字节的PTE，那么我们将需要一个始终驻留在内存中的4MB页表，即使应用程序只引用了虚拟地址空间的一小部分。对于具有64位地址空间的系统来说，这个问题更加复杂。

The common approach for compacting the page table is to use a hierarchy of page tables instead. The idea is easiest to understand with a concrete example. Consider a 32-bit virtual address space partitioned into 4 KB pages, with page table entries that are 4 bytes each. Suppose also that at this point in time the virtual address space has the following form: The first 2 K pages of memory are allocated for code and data, the next 6 K pages are unallocated, the next 1,023 pages are also unallocated, and the next page is allocated for the user stack. Figure 9.17 shows how we might construct a two-level page table hierarchy for this virtual address space.

压缩页表的常用方法是使用页表的层次结构。通过一个具体的例子，这个想法最容易理解。考虑一个32位的虚拟地址空间，它被划分为4KB的页面，每个页面表条目有4个字节。还假设此时虚拟地址空间具有以下形式：前2k页内存分配给代码和数据，接下来的6k页未分配，接下来的1023页也未分配，下一页分配给用户堆栈。图9.17显示了我们如何为这个虚拟地址空间构建两级页表层次结构。

Each PTE in the level 1 table is responsible for mapping a 4 MB chunk of the virtual address space, where each chunk consists of 1,024 contiguous pages. For example, PTE 0 maps the first chunk, PTE 1 the next chunk, and so on. Given that the address space is 4 GB, 1,024 PTEs are sufficient to cover the entire space.

级别1表中的每个PTE负责映射一个4MB的虚拟地址空间块，其中每个块由1024个连续页面组成。例如，PTE 0映射第一个块，PTE 1映射下一个块，依此类推。假设地址空间为4GB，1024个PTE足以覆盖整个空间。

If every page in chunk i is unallocated, then level 1 PTE i is null. For example, in Figure 9.17 , chunks 2--7 are unallocated. However, if at least one page in chunk i is allocated, then level 1 PTE i points to the base of a level 2 page table. For example, in Figure 9.17 , all or portions of chunks 0,1, and 8 are allocated, so their level 1 PTEs point to level 2 page tables.

如果chunk i中的每个页面都未分配，则level 1 PTE i为空。例如，在图9.17中，块2-7是未分配的。然而，如果区块i中至少分配了一个页面，则级别1 PTE i指向级别2页面表的底部。例如，在图9.17中，分配了块0、1和8的全部或部分，因此它们的1级PTE指向2级页面表。

Each PTE in a level 2 page table is responsible for mapping a 4-KB page of virtual memory, just as before when we looked at single-level page tables. Notice that with 4-byte PTEs, each level 1 and level 2 page table is 4 kilobytes, which conveniently is the same size as a page.

二级页表中的每个PTE负责映射一个4KB页的虚拟内存，就像我们之前研究单级页表时一样。请注意，对于4字节的PTE，每个级别1和级别2的页面表都是4KB，方便地与页面大小相同。

This scheme reduces memory requirements in two ways. First, if a PTE in the level 1 table is null, then the corresponding level 2 page table does not even have to exist. This represents a significant potential savings, since most of the 4 GB virtual address space for a typical program is unallocated. Second, only the level 1 table needs to be in main memory at all times. The level 2 page tables can be created and paged in and out by the VM system as they are needed, which reduces pressure on main memory. Only the most heavily used level 2 page tables need to be cached in main memory.

该方案从两个方面降低了内存需求。首先，如果级别1表中的PTE为空，则相应的级别2页表甚至不必存在。这意味着一个显著的潜在节约，因为一个典型程序的大部分4GB虚拟地址空间是未分配的。其次，只有级别1的表始终需要在主内存中。二级页面表可以根据需要由VM系统创建和调出，这减少了主内存的压力。只有使用最频繁的2级页面表需要缓存在主内存中。

Figure 9.18 summarizes address translation with a k-level page table hierarchy. The virtual address is partitioned into k VPNs and a VPO. Each VPN i, 1 ≤ i ≤ k, is an index into a page table at level i. Each PTE in a level j table, 1 ≤ j ≤ k − 1, points to the base of some page table at level j + 1. Each PTE in a level k table contains either the PPN of some physical page or the address of a disk block. To construct the physical address, the MMU must access k PTEs before it can determine the PPN. As with a single-level hierarchy, the PPO is identical to the VPO

图9.18总结了具有k级页表层次结构的地址转换。该虚拟地址被划分为k个VPN和一个VPO。每个VPNi，1≤i≤k是到第i级的页表的索引。j级表1≤j≤k−1中的每个PTE指向在j+1级的某个页表的基址。k级表中的每个PTE包含某个物理页的PPN或磁盘块的地址。为了构造物理地址，MMU必须先访问k个PTE，然后才能确定PPN。与单级分层结构一样，PPO与VPO相同

Accessing k PTEs may seem expensive and impractical at first glance. However, the TLB comes to the rescue here by caching PTEs from the page tables at the different levels. In practice, address translation with multi-level page tables is not significantly slower than with single-level page tables.

乍一看，访问k PTE可能会显得昂贵且不切实际。然而，TLB通过在不同级别缓存页面表中的PTE来解救这个问题。实际上，使用多级页表进行地址转换并不比使用单层页表慢多少。

## 9.7 Case Study: The Intel Core i7/Linux Memory System

We conclude our discussion of virtual memory mechanisms with a case study of a real system: an Intel Core i7 running Linux. Although the underlying Haswell microarchitecture allows for full 64-bit virtual and physical address spaces, the current Core i7 implementations (and those for the foreseeable future) support a 48-bit (256 TB) virtual address space and a 52-bit (4 PB) physical address space, along with a compatibility mode that supports 32-bit (4 GB) virtual and physical address spaces.

我们以一个实际系统的案例研究来结束我们对虚拟内存机制的讨论：运行Linux的Intel Corei7。尽管底层的Haswell微体系结构允许完整的64位虚拟和物理地址空间，但当前的Core i7实现(以及可预见的未来)支持48位(256 TB)虚拟地址空间和52位(4 PB)物理地址空间，以及支持32位(4 GB)虚拟和物理地址空间的兼容模式。

Figure 9.21 gives the highlights of the Core i7 memory system. The processor package (chip) includes four cores, a large L3 cache shared by all of the cores, and a DDR3 memory controller. Each core contains a hierarchy of TLBs, a hierarchy of data and instruction caches, and a set of fast point-topoint links, based on the QuickPath technology, for communicating directly with the other cores and the external I/O bridge. The TLBs are virtually addressed, and 4-way set associative. The L1, L2, and L3 caches are physically addressed, with a block size of 64 bytes. L1 and L2 are 8-way set associative, and L3 is 16-way set associative. The page size can be configured at start-up time as either 4 KB or 4 MB. Linux uses 4 KB pages.

图9.21给出了Core i7内存系统的亮点。处理器包（芯片）包括四个内核，一个所有内核共享的大型L3缓存，以及一个DDR3内存控制器。每个内核都包含一个TLB的层次结构，一个数据和指令缓存的层次结构，以及一套基于QuickPath技术的快速点对点链接，用于与其他内核和外部I/O桥直接通信。TLB是虚拟寻址的，并且是4路集合关联的。L1、L2和L3缓存是物理寻址的，块大小为64字节。L1和L2是8路设置关联的，L3是16路设置关联的。页面大小可以在启动时被配置为4KB或4MB。Linux使用4KB的页面。

### 9.7.1 Core i7 Address Translation

Figure 9.22 summarizes the entire Core i7 address translation process, from the time the CPU generates a virtual address until a data word arrives from memory. The Core i7 uses a four-level page table hierarchy. Each process has its own private page table hierarchy. When a Linux process is running, the page tables associated with allocated pages are all memory-resident, although the Core i7 architecture allows these page tables to be swapped in and out. The CR3 control register contains the physical address of the beginning of the level 1 (L1) page table. The value of CR3 is part of each process context, and is restored during each context switch

图9.22总结了整个Core i7的地址转换过程，从CPU生成虚拟地址开始，直到数据字从内存到达。Core i7使用了一个四级页表层次结构。每个进程都有自己的私有页表层次结构。当Linux进程运行时，与分配的页面相关的页表都是驻留在内存中的，尽管Core i7架构允许这些页表被换入和换出。CR3控制寄存器包含第一级（L1）页表开始的物理地址。CR3的值是每个进程上下文的一部分，并在每次上下文切换时被恢复。

Figure 9.23 shows the format of an entry in a level 1, level 2, or level 3 page table. When P = 1 (which is always the case with Linux), the address field contains a 40-bit physical page number (PPN) that points to the beginning of the appropriate page table. Notice that this imposes a 4 KB alignment requirement on page tables

图9.23显示了1级、2级或3级页面表格中条目的格式。当P=1时（Linux总是这样），地址字段包含一个40位物理页码（PPN），它指向相应页表的开头。请注意，这对页表提出了4KB的对齐要求

Figure 9.24 shows the format of an entry in a level 4 page table. When P = 1, the address field contains a 40-bit PPN that points to the base of some page in physical memory. Again, this imposes a 4 KB alignment requirement on physical pages.

图9.24显示了4级页面表格中条目的格式。当P=1时，地址字段包含一个40位PPN，它指向物理内存中某个页面的底部。同样，这对物理页面提出了4KB的对齐要求。

The PTE has three permission bits that control access to the page. The R/W bit determines whether the contents of a page are read/write or read-only. The U/S bit, which determines whether the page can be accessed in user mode, protects code and data in the operating system kernel from user programs. The XD (execute disable) bit, which was introduced in 64-bit systems, can be used to disable instruction fetches from individual memory pages. This is an important new feature that allows the operating system kernel to reduce the risk of buffer overflow attacks by restricting execution to the read-only code segment.

PTE有三个权限位来控制对页面的访问。R/W位决定页面的内容是读/写还是只读。决定页面是否可以以用户模式访问的U/S位，保护操作系统内核中的代码和数据不受用户程序的影响。在64位系统中引入的XD(禁用执行)位可用于禁用从单个内存页提取指令。这是一个重要的新特性，它允许操作系统内核通过限制执行只读代码段来减少缓冲区溢出攻击的风险。

As the MMU translates each virtual address, it also updates two other bits that can be used by the kernel's page fault handler. The MMU sets the A bit, which is known as a reference bit, each time a page is accessed. The kernel can use the reference bit to implement its page replacement algorithm. The MMU sets the D bit, or dirty bit, each time the page is written to. A page that has been modified is sometimes called a dirty page. The dirty bit tells the kernel whether or not it must write back a victim page before it copies in a replacement page. The kernel can call a special kernel-mode instruction to clear the reference or dirty bits.

当MMU转换每个虚拟地址时，它也更新其他两个位，以供内核的页面错误处理程序使用。MMU在每次访问一个页面时设置A位，这被称为一个参考位。内核可以使用引用位来实现它的页面替换算法。MMU在每次写入页面时设置D位，即脏位。被修改过的页面有时被称为脏页面。脏位告诉内核在复制替换页之前是否必须回写受害者页。内核可以调用一个特殊的内核模式指令来清除引用或脏位。

Figure 9.25 shows how the Core i7 MMU uses the four levels of page tables to translate a virtual address to a physical address. The 36-bit VPN is partitioned into four 9-bit chunks, each of which is used as an offset into a page table. The CR3 register contains the physical address of the L1 page table. VPN 1 provides an offset to an L1 PTE, which contains the base address of the L2 page table. VPN 2 provides an offset to an L2 PTE, and so on

图9.25展示了Core i7 MMU如何使用四层页表将虚拟地址转换为物理地址。36位VPN被划分为4个9位的块，每个块作为页表的偏移量。CR3寄存器包含L1页表的物理地址。VPN 1提供了一个到L1 PTE的偏移量，它包含L2页表的基址。VPN 2提供一个到L2 PTE的偏移量，依此类推

### 9.7.2 Linux Virtual Memory System

A virtual memory system requires close cooperation between the hardware and the kernel. Details vary from version to version, and a complete description is beyond our scope. Nonetheless, our aim in this section is to describe enough of the Linux virtual memory system to give you a sense of how a real operating system organizes virtual memory and how it handles page faults.

虚拟内存系统需要硬件和内核之间的密切合作。细节因版本而异，完整的描述超出了我们的范围。尽管如此，我们在本节中的目标是描述足够多的Linux虚拟内存系统，让您了解真实操作系统如何组织虚拟内存，以及它如何处理页面错误。

Linux maintains a separate virtual address space for each process of the form shown in Figure 9.26 . We have seen this picture a number of times already, with its familiar code, data, heap, shared library, and stack segments. Now that we understand address translation, we can fill in some more details about the kernel virtual memory that lies above the user stack.

Linux为每个进程维护一个单独的虚拟地址空间，如图9.26所示。我们已经多次看到过这幅图，以及它熟悉的代码、数据、堆、共享库和堆栈段。现在，我们已经了解了地址转换，我们可以详细介绍位于用户堆栈之上的内核虚拟内存。

The kernel virtual memory contains the code and data structures in the kernel. Some regions of the kernel virtual memory are mapped to physical pages that are shared by all processes. For example, each process shares the kernel's code and global data structures. Interestingly, Linux also maps a set of contiguous virtual pages (equal in size to the total amount of DRAM in the system) to the corresponding set of contiguous physical pages. This provides the kernel with a convenient way to access any specific location in physical memory—for example, when it needs to access page tables or to perform memory-mapped I/O operations on devices that are mapped to particular physical memory locations.

内核虚拟内存包含内核中的代码和数据结构。内核虚拟内存的某些区域映射到所有进程共享的物理页。例如，每个进程共享内核的代码和全局数据结构。有趣的是，Linux还将一组连续的虚拟页（大小等于系统中的DRAM总量）映射到相应的一组连续物理页。这为内核提供了访问物理内存中任何特定位置的方便方法，例如，当内核需要访问页表或在映射到特定物理内存位置的设备上执行内存映射I/O操作时。

In our discussion of address translation, we have described a sequential two-step process where the MMU (1) translates the virtual address to a physical address and then (2) passes the physical address to the L1 cache. However, real hardware implementations use a neat trick that allows these steps to be partially overlapped, thus speeding up accesses to the L1 cache. For example, a virtual address on a Core i7 with 4 KB pages has 12 bits of VPO, and these bits are identical to the 12 bits of PPO in the corresponding physical address. Since the 8way set associative physically addressed L1 caches have 64 sets and 64-byte cache blocks, each physical address has 6 (log 64) cache offset bits and 6 (log 64) index bits. These 12 bits fit exactly in the 12-bit VPO of a virtual address, which is no accident! When the CPU needs a virtual address translated, it sends the VPN to the MMU and the VPO to the L1 cache. While the MMU is requesting a page table entry from the TLB, the L1 cache is busy using the VPO bits to find the appropriate set and read out the eight tags and corresponding data words in that set. When the MMU gets the PPN back from the TLB, the cache is ready to try to match the PPN to one of these eight tags.

在我们对地址转换的讨论中，我们描述了一个连续的两步过程，其中MMU（1）将虚拟地址转换为物理地址，然后（2）将物理地址传递给一级缓存。然而，真正的硬件实现使用了一种巧妙的技巧，允许这些步骤部分重叠，从而加快了对一级缓存的访问。例如，具有4KB页面的Core i7上的虚拟地址有12位VPO，这些位与相应物理地址中的12位PPO相同。由于8路集关联物理寻址一级缓存有64个集和64字节缓存块，每个物理地址有6个（日志64）缓存偏移位和6个（日志64）索引位。这12位正好适合虚拟地址的12位VPO，这绝非偶然！当CPU需要转换虚拟地址时，它会将VPN发送到MMU，将VPO发送到一级缓存。当MMU从TLB请求页面表条目时，一级缓存正忙于使用VPO位来找到适当的集合，并读取该集合中的八个标记和相应的数据字。当MMU从TLB获取PPN时，缓存准备好尝试将PPN与这八个标记中的一个匹配。

Other regions of kernel virtual memory contain data that differ for each process. Examples include page tables, the stack that the kernel uses when it is executing code in the context of the process, and various data structures that keep track of the current organization of the virtual address space.

内核虚拟内存的其他区域包含每个进程不同的数据。示例包括页表、内核在进程上下文中执行代码时使用的堆栈，以及跟踪虚拟地址空间的当前组织的各种数据结构。

#### Linux Virtual Memory Areas

Linux organizes the virtual memory as a collection of areas (also called segments). An area is a contiguous chunk of existing (allocated) virtual memory whose pages are related in some way. For example, the code segment, data segment, heap, shared library segment, and user stack are all distinct areas. Each existing virtual page is contained in some area, and any virtual page that is not part of some area does not exist and cannot be referenced by the process. The notion of an area is important because it allows the virtual address space to have gaps. The kernel does not keep track of virtual pages that do not exist, and such pages do not consume any additional resources in memory, on disk, or in the kernel itself.

Linux 将虚拟内存组织为一组区域（也称为段）。区域是现有（分配的）虚拟内存的连续块，其页面以某种方式相关。例如，代码段、数据段、堆、共享库段和用户栈都是不同的区域。每个现有的虚拟页面都包含在某个区域中，任何不属于某个区域的虚拟页面都不存在并且不能被进程引用。区域的概念很重要，因为它允许虚拟地址空间存在间隙。内核不会跟踪不存在的虚拟页面，并且这些页面不会消耗内存、磁盘或内核本身中的任何额外资源。

Figure 9.27 highlights the kernel data structures that keep track of the virtual memory areas in a process. The kernel maintains a distinct task structure ( task_struct in the source code) for each process in the system. The elements of the task structure either contain or point to all of the information that the kernel needs to run the process (e.g., the PID, pointer to the user stack, name of the executable object file, and program counter).

图 9.27 突出显示了跟踪进程中的虚拟内存区域的内核数据结构。内核为系统中的每个进程维护一个独特的任务结构（源代码中的 task_struct）。任务结构的元素包含或指向内核运行进程所需的所有信息（例如，PID、指向用户堆栈的指针、可执行目标文件的名称和程序计数器）。

One of the entries in the task structure points to an mm_struct that characterizes the current state of the virtual memory. The two fields of interest to us are pgd , which points to the base of the level 1 table (the page global directory), and mmap , which points to a list of vm_area_structs (area structs), each of which characterizes an area of the current virtual address space. When the kernel runs this process, it stores pgd in the CR3 control register.

任务结构中的一个条目指向表征虚拟内存当前状态的mm_struct。我们感兴趣的两个字段是pgd和mmap，前者指向Level 1表(页面全局目录)的基址，后者指向一组vm_area_structs(区域结构)，每个结构都表示当前虚拟地址空间的一个区域。当内核运行此进程时，它会将PGD存储在CR3控制寄存器中。

For our purposes, the area struct for a particular area contains the following fields: fvm_start . Points to the beginning of the area. vm_end . Points to the end of the area. vm_prot . Describes the read/write permissions for all of the pages contained in the area. vm_flags . Describes (among other things) whether the pages in the area are shared with other processes or private to this process. vm_next . Points to the next area struct in the list.

出于我们的目的，特定区域的区域结构包含以下字段：FVM_START。指向区域的起点。Vm_end。指向区域的末端。Vm_prot。描述区域中包含的所有页面的读/写权限。VM_FLAGS。描述区域中的页面是与其他进程共享还是此进程专用。Vm_Next。指向列表中的下一个区域结构。

#### Linux Page Fault Exception Handling

Suppose the MMU triggers a page fault while trying to translate some virtual address A. The exception results in a transfer of control to the kernel's page fault handler, which then performs the following steps:

假设MMU在尝试转换某个虚拟地址a时触发了一个页面错误。异常会导致控制权转移到内核的页面错误处理程序，该处理程序随后执行以下步骤：

Is virtual address A legal? In other words, does A lie within an area defined by some area struct? To answer this question, the fault handler searches the list of area structs, comparing A with the vm_start and vm_end in each area struct. If the instruction is not legal, then the fault handler triggers a segmentation fault, which terminates the process. This situation is labeled "1" in Figure 9.28 . Because a process can create an arbitrary number of new virtual memory areas (using the mmap function described in the next section), a sequential search of the list of area structs might be very costly. So in practice, Linux superimposes a tree on the list, using some fields that we have not shown, and performs the search on this tree.

虚拟地址A合法吗?换句话说，A是否位于某个区域结构定义的区域内?为了回答这个问题，故障处理程序搜索区域结构的列表，将A与每个区域结构中的vm_start和vm_end进行比较。如果指令不合法，则故障处理程序触发分段故障，从而终止进程。这种情况在图9.28中被标记为“1”。由于进程可以创建任意数量的新虚拟内存区域(使用下一节中描述的mmap函数)，因此对区域结构列表的顺序搜索可能代价非常高。所以在实践中，Linux使用一些我们没有显示的字段，将树叠加到列表上，并在这棵树上执行搜索。

Is the attempted memory access legal? In other words, does the process have permission to read, write, or execute the pages in this area? For example, was the page fault the result of a store instruction trying to write to a read-only page in the code segment? Is the page fault the result of a process running in user mode that is attempting to read a word from kernel virtual memory? If the attempted access is not legal, then the fault handler triggers a protection exception, which terminates the process. This situation is labeled "2" in Figure 9.28 .

尝试的内存访问是否合法？换句话说，进程是否有权读取、写入或执行该区域中的页面？例如，页面错误是存储指令试图写入代码段中的只读页面的结果吗？页面错误是否是在用户模式下运行的进程试图从内核虚拟内存中读取单词的结果？如果尝试的访问不合法，则故障处理程序会触发保护异常，从而终止进程。这种情况在图 9.28 中标记为“2”。

At this point, the kernel knows that the page fault resulted from a legal operation on a legal virtual address. It handles the fault by selecting a victim page, swapping out the victim page if it is dirty, swapping in the new page, and updating the page table. When the page fault handler returns, the CPU restarts the faulting instruction, which sends A to the MMU again. This time, the MMU translates A normally, without generating a page fault.

此时，内核知道页面错误是由对合法虚拟地址的合法操作引起的。它通过选择一个受害者页面、如果它是脏的则换出受害者页面、换入新页面以及更新页表来处理故障。当页面错误处理程序返回时，CPU 重新启动错误指令，该指令再次将 A 发送到 MMU。这一次，MMU 正常翻译 A，而不会产生页面错误。

## 9.8 Memory Mapping

Linux initializes the contents of a virtual memory area by associating it with an object on disk, a process known as memory mapping. Areas can be mapped to one of two types of objects:

Linux通过将虚拟内存区域与磁盘上的对象关联来初始化虚拟内存区域的内容，这一过程称为内存映射。区域可以映射到两种类型的对象之一：

Regular file in the Linux file system: An area can be mapped to a contiguous section of a regular disk file, such as an executable object file. The file section is divided into page-size pieces, with each piece containing the initial contents of a virtual page. Because of demand paging, none of these virtual pages is actually swapped into physical memory until the CPU first touches the page (i.e., issues a virtual address that falls within that page's region of the address space). If the area is larger than the file section, then the area is padded with zeros.

Linux文件系统中的常规文件：一个区域可以映射到常规磁盘文件的连续部分，例如可执行目标文件。文件节分为多个页面大小的片段，每个片段包含虚拟页面的初始内容。由于按需分页，这些虚拟页实际上都不会被交换到物理内存中，直到CPU第一次接触到该页(即发出一个落在该页的地址空间区域内的虚拟地址)。如果区域大于文件部分，则用零填充该区域。

Anonymous file: An area can also be mapped to an anonymous file, created by the kernel, that contains all binary zeros. The first time the CPU touches a virtual page in such an area, the kernel finds an appropriate victim page in physical memory, swaps out the victim page if it is dirty, overwrites the victim page with binary zeros, and updates the page table to mark the page as resident. Notice that no data are actually transferred between disk and memory. For this reason, pages in areas that are mapped to anonymous files are sometimes called demand-zero pages.

匿名文件:一个区域也可以映射到一个由内核创建的匿名文件，该文件包含所有二进制零。当CPU第一次接触到这个区域中的一个虚拟页时，内核会在物理内存中找到一个合适的“受害者”页，如果这个“受害者”页是脏的，就交换掉它，用二进制零覆盖这个“受害者”页，并更新页表，将该页标记为“常驻”。注意，磁盘和内存之间实际上没有传输数据。出于这个原因，映射到匿名文件的区域中的页面有时被称为零需求页面。

In either case, once a virtual page is initialized, it is swapped back and forth between a special swap file maintained by the kernel. The swap file is also known as the swap space or the swap area. An important point to realize is that at any point in time, the swap space bounds the total amount of virtual pages that can be allocated by the currently running processes.

在这两种情况下，一旦初始化了虚拟页，它就会在内核维护的一个特殊交换文件之间来回交换。交换文件也称为交换空间或交换区域。需要注意的一点是，在任何时候，交换空间都会限制当前运行的进程可以分配的虚拟页的总量。

### 9.8.1 Shared Objects Revisited

The idea of memory mapping resulted from a clever insight that if the virtual memory system could be integrated into the conventional file system, then it could provide a simple and efficient way to load programs and data into memory.

内存映射的想法源于一个聪明的想法:如果虚拟内存系统可以集成到传统的文件系统中，那么它就可以提供一种简单而有效的方式来将程序和数据加载到内存中。

As we have seen, the process abstraction promises to provide each process with its own private virtual address space that is protected from errant writes or reads by other processes. However, many processes have identical read-only code areas. For example, each process that runs the Linux shell program bash has the same code area. Further, many programs need to access identical copies of readonly run-time library code. For example, every C program requires functions from the standard C library such as printf . It would be extremely wasteful for each process to keep duplicate copies of these commonly used codes in physical memory. Fortunately, memory mapping provides us with a clean mechanism for controlling how objects are shared by multiple processes.

正如我们所看到的，进程抽象承诺为每个进程提供它自己的私有虚拟地址空间，以防止其他进程错误地写或读。但是，许多进程都有相同的只读代码区。例如，运行Linux shell程序bash的每个进程都有相同的代码区。而且，许多程序需要访问只读运行时库代码的相同副本。例如，每个C程序都需要来自标准C库的函数，如printf。对于每个进程来说，在物理内存中保留这些常用代码的副本是极其浪费的。幸运的是，内存映射为我们提供了一种干净的机制来控制多个进程如何共享对象。

An object can be mapped into an area of virtual memory as either a shared object or a private object. If a process maps a shared object into an area of its virtual address space, then any writes that the process makes to that area are visible to any other processes that have also mapped the shared object into their virtual memory. Further, the changes are also reflected in the original object on disk.

对象可以作为共享对象或私有对象映射到虚拟内存区域。如果一个进程将一个共享对象映射到它的虚拟地址空间的某个区域，那么该进程对该区域的任何写操作，对于同样将该共享对象映射到其虚拟内存中的其他进程都是可见的。此外，更改还反映在磁盘上的原始对象中。

Changes made to an area mapped to a private object, on the other hand, are not visible to other processes, and any writes that the process makes to the area are not reflected back to the object on disk. A virtual memory area into which a shared object is mapped is often called a shared area. Similarly for a private area.

另一方面，对映射到私有对象的区域所做的更改对其他进程不可见，进程对该区域所做的任何写入都不会反映回磁盘上的对象。共享对象映射到的虚拟内存区域通常称为共享区域。私人区域也是如此。

Suppose that process 1 maps a shared object into an area of its virtual memory, as shown in Figure 9.29(a) . Now suppose that process 2 maps the same shared object into its address space (not necessarily at the same virtual address as process 1), as shown in Figure 9.29(b) .

假设进程1将一个共享对象映射到它的虚拟内存中，如图9.29(a)所示。现在，假设进程2将同一个共享对象映射到它的地址空间(不一定与进程1在同一个虚拟地址)，如图9.29(b)所示。

Since each object has a unique filename, the kernel can quickly determine that process 1 has already mapped this object and can point the page table entries in process 2 to the appropriate physical pages. The key point is that only a single copy of the shared object needs to be stored in physical memory, even though the object is mapped into multiple shared areas. For convenience, we have shown the physical pages as being contiguous, but of course this is not true in general.

由于每个对象都有一个惟一的文件名，内核可以快速确定进程1已经映射了这个对象，并可以将进程2中的页表项指向适当的物理页。关键在于，即使对象被映射到多个共享区域，也只需要将共享对象的一个副本存储在物理内存中。为了方便起见，我们将物理页面显示为连续的，但当然一般情况下并非如此。

Private objects are mapped into virtual memory using a clever technique known as copy-on-write. A private object begins life in exactly the same way as a shared object, with only one copy of the private object stored in physical memory. For example, Figure 9.30(a) shows a case where two processes have mapped a private object into different areas of their virtual memories but share the same physical copy of the object. For each process that maps the private object, the page table entries for the corresponding private area are flagged as read-only, and the area struct is flagged as private copyon-write. So long as neither process attempts to write to its respective private area, they continue to share a single copy of the object in physical memory. However, as soon as a process attempts to write to some page in the private area, the write triggers a protection fault.

私有对象使用一种称为写时复制(copy-on-write)的聪明技术映射到虚拟内存。私有对象以与共享对象完全相同的方式开始生命，只有一个私有对象的副本存储在物理内存中。例如，图9.30(a)显示了这样一种情况:两个进程将一个私有对象映射到各自虚拟内存的不同区域，但共享该对象的相同物理副本。对于映射私有对象的每个进程，对应的私有区域的页表条目被标记为只读，区域结构被标记为私有copy- write。只要两个进程都没有尝试对各自的私有区域进行写操作，它们就会继续在物理内存中共享该对象的单个副本。但是，一旦进程试图对私有区域中的某个页进行写操作，就会触发保护故障。

When the fault handler notices that the protection exception was caused by the process trying to write to a page in a private copy-onwrite area, it creates a new copy of the page in physical memory, updates the page table entry to point to the new copy, and then restores write permissions to the page, as shown in Figure 9.30(b) . When the fault handler returns, the CPU re-executes the write, which now proceeds normally on the newly created page.

当故障处理程序注意到保护异常是由试图写入私有副本onwrite区域中的页面的进程引起时，它会在物理内存中创建页面的新副本，更新页面表条目以指向新副本，然后恢复对页面的写入权限，如图9.30（b）所示。当故障处理程序返回时，CPU会重新执行写入操作，写入操作现在会在新创建的页面上正常进行。

By deferring the copying of the pages in private objects until the last possible moment, copy-on-write makes the most efficient use of scarce physical memory.

通过将私有对象中的页面复制推迟到最后一刻，写时复制可以最有效地利用稀缺的物理内存。

### 9.8.2 The fork Function Revisited

Now that we understand virtual memory and memory mapping, we can get a clear idea of how the fork function creates a new process with its own independent virtual address space.

既然我们理解了虚拟内存和内存映射，我们就可以清楚地了解fork函数是如何创建一个具有自己独立虚拟地址空间的新进程的。

When the fork function is called by the current process, the kernel creates various data structures for the new process and assigns it a unique PID. To create the virtual memory for the new process, it creates exact copies of the current process's mm_struct , area structs, and page tables. It flags each page in both processes as read-only, and flags each area struct in both processes as private copy-on-write.

当fork函数被当前进程调用时，内核会为新进程创建各种数据结构，并为其分配一个唯一的PID。要为新进程创建虚拟内存，需要创建当前进程mm_struct、area struct和page table的精确副本。它将两个进程中的每个页面标记为只读，并将两个进程中的每个区域结构标记为私有的copy-on-write。

When the fork returns in the new process, the new process now has an exact copy of the virtual memory as it existed when the fork was called. When either of the processes performs any subsequent writes, the copy-on-write mechanism creates new pages, thus preserving the abstraction of a private address space for each process.

当fork在新进程中返回时，新进程现在拥有了调用该fork时存在的虚拟内存的确切副本。当其中一个进程执行任何后续写操作时，即写即拷机制将创建新页面，从而为每个进程保留一个私有地址空间的抽象。

### 9.8.3 The execve Function Revisited

Virtual memory and memory mapping also play key roles in the process of loading programs into memory. Now that we understand these concepts, we can understand how the execve function really loads and executes programs. Suppose that the program running in the current process makes the following call:

虚拟内存和内存映射在将程序加载到内存的过程中也起着关键作用。既然我们理解了这些概念，我们就可以理解execute函数是如何真正加载和执行程序的。假设在当前进程中运行的程序进行了以下调用:

execve("a.out", NULL, NULL);

As you learned in Chapter 8 , the execve function loads and runs the program contained in the executable object file a.out within the current process, effectively replacing the current program with the a.out program. Loading and running a.out requires the following steps:

正如您在第8章中所学到的，执行函数在当前进程中加载并运行可执行对象文件a.out中包含的程序，从而有效地将当前程序替换为a.out程序。加载和运行a.out需要以下步骤:

Delete existing user areas. Delete the existing area structs in the user portion of the current process's virtual address.

删除已有用户区域。删除当前进程虚拟地址的用户部分中的现有区域结构。

Map private areas. Create new area structs for the code, data, bss, and stack areas of the new program. All of these new areas are private copy-on-write. The code and data areas are mapped to the .text and .data sections of the a.out file. The bss area is demand-zero, mapped to an anonymous file whose size is contained in a.out . The stack and heap area are also demand-zero, initially of zero length. Figure 9.31 summarizes the different mappings of the private areas.

映射私人区域。为新程序的代码、数据、bss 和堆栈区域创建新的区域结构。所有这些新区域都是私有的写时复制。代码和数据区域映射到 a.out 文件的 .text 和 .data 部分。 bss 区域的需求为零，映射到一个匿名文件，其大小包含在 a.out 中。堆栈和堆区域也是零需求，最初的长度为零。图 9.31 总结了私有区域的不同映射。

Map shared areas. If the a.out program was linked with shared objects, such as the standard C library libc.so , then these objects are dynamically linked into the program, and then mapped into the shared region of the user's virtual address space.

映射共享区域。如果 a.out 程序与共享对象链接，例如标准 C 库 libc.so ，那么这些对象会动态链接到程序中，然后映射到用户虚拟地址空间的共享区域。

Set the program counter (PC). The last thing that execve does is to set the program counter in the current process's context to point to the entry point in the code area.

设置程序计数器 (PC)。 execve 做的最后一件事是设置当前进程上下文中的程序计数器指向代码区的入口点。

The next time this process is scheduled, it will begin execution from the entry point. Linux will swap in code and data pages as needed.

下次安排此进程时，它将从入口点开始执行。 Linux 将根据需要交换代码和数据页。

### 9.8.4 User-Level Memory Mapping with the mmap Function

Linux processes can use the mmap function to create new areas of virtual memory and to map objects into these areas.

Linux进程可以使用mmap函数创建虚拟内存的新区域，并将对象映射到这些区域。

The mmap function asks the kernel to create a new virtual memory area, preferably one that starts at address start , and to map a contiguous chunk of the object specified by file descriptor fd to the new area. The contiguous object chunk has a size of length bytes and starts at an offset of offset bytes from the beginning of the file. The start address is merely a hint, and is usually specified as NULL. For our purposes, we will always assume a NULL start address. Figure 9.32 depicts the meaning of these arguments.

mmap函数要求内核创建一个新的虚拟内存区域，最好是从地址start开始的，并将由文件描述符fd指定的对象的连续块映射到新区域。连续对象块的大小为长度字节，并且从文件开头的偏移字节的偏移量开始。起始地址仅仅是一个提示，通常被指定为NULL。出于我们的目的，我们总是假设起始地址为NULL。图9.32描述了这些参数的含义。

The prot argument contains bits that describe the access permissions of the newly mapped virtual memory area (i.e., the vm_prot bits in the corresponding area struct).

prot参数包含描述新映射的虚拟内存区域访问权限的位(即对应区域结构中的vm_prot位)。

PROT_EXEC. Pages in the area consist of instructions that may be executed by the CPU. PROT_READ. Pages in the area may be read. PROT_WRITE. Pages in the area may be written. PROT_NONE. Pages in the area cannot be accessed.

PROT_EXEC。该区域中的页面包含可由 CPU 执行的指令。 PROT_READ。可以阅读该区域中的页面。 PROT_WRITE。可以写入该区域中的页面。 PROT_NONE。无法访问该区域中的页面。

The flags argument consists of bits that describe the type of the mapped object. If the MAP_ANON flag bit is set, then the backing store is an anonymous object and the corresponding virtual pages are demand-zero. MAP_PRIVATE indicates a private copy-on-write object, and MAP_SHARED indicates a shared object. For example,

flags 参数由描述映射对象类型的位组成。如果设置了 MAP_ANON 标志位，则后备存储是一个匿名对象，并且相应的虚拟页面是零需求。 MAP_PRIVATE 表示私有写时复制对象，MAP_SHARED 表示共享对象。例如，

bufp = Mmap(NULL, size, PROT_READ, MAP_PRIVATEIMAP_ANON, 0, 0);

asks the kernel to create a new read-only, private, demand-zero area of virtual memory containing size bytes. If the call is successful, then bufp contains the address of the new area.

要求内核创建一个新的只读、私有、需求为零的虚拟内存区域，其中包含 size 个字节。如果调用成功，则 bufp 包含新区域的地址。

The munmap function deletes the area starting at virtual address start and consisting of the next length bytes. Subsequent references to the deleted region result in segmentation faults.

munmap 函数删除从虚拟地址 start 开始并由下一个长度字节组成的区域。对已删除区域的后续引用会导致分段错误。

## 9.9 Dynamic Memory Allocation

While it is certainly possible to use the low-level mmap and munmap functions to create and delete areas of virtual memory, C programmers typically find it more convenient and more portable to use a dynamic memory allocator when they need to acquire additional virtual memory at run time.

虽然当然可以使用低级的mmap和munmap函数来创建和删除虚拟内存区域，但C程序员通常发现，当他们需要在运行时获得额外的虚拟内存时，使用动态内存分配器更方便、更可移植。

A dynamic memory allocator maintains an area of a process's virtual memory known as the heap (Figure 9.33 ). Details vary from system to system, but without loss of generality, we will assume that the heap is an area of demand-zero memory that begins immediately after the uninitialized data area and grows upward (toward higher addresses). For each process, the kernel maintains a variable brk (pronounced "break") that points to the top of the heap.

动态内存分配器维护进程虚拟内存中的一个区域，称为堆(图9.33)。具体信息因系统而异，但在不丧失通用性的情况下，我们假定堆是一个需求为零的内存区域，它立即开始于未初始化的数据区域，并向上增长(向更高的地址)。对于每个进程，内核维护一个变量brk(发音为“break”)，该变量指向堆的顶部。

An allocator maintains the heap as a collection of various-size blocks. Each block is a contiguous chunk of virtual memory that is either allocated or free. An allocated block has been explicitly reserved for use by the application. A free block is available to be allocated. A free block remains free until it is explicitly allocated by the application. An allocated block remains allocated until it is freed, either explicitly by the application or implicitly by the memory allocator itself.

分配器将堆维护为各种大小块的集合。每个块都是一个连续的虚拟内存块，要么是分配的，要么是空闲的。已分配的块已明确保留供应用程序使用。有一个空闲块可供分配。空闲块在应用程序显式分配之前一直是空闲的。分配的块在被释放之前一直保持分配状态，无论是由应用程序显式释放还是由内存分配器本身隐式释放。

Allocators come in two basic styles. Both styles require the application to explicitly allocate blocks. They differ about which entity is responsible for freeing allocated blocks.

分配器有两种基本形式。这两种风格都要求应用程序显式分配块。它们的不同之处在于哪个实体负责释放分配的块。

Explicit allocators require the application to explicitly free any allocated blocks. For example, the C standard library provides an explicit allocator called the malloc package. C programs allocate a block by calling the malloc function, and free a block by calling the free function. The new and delete calls in C++ are comparable.

显式分配器要求应用程序显式释放任何已分配的块。例如，C标准库提供了一个名为malloc包的显式分配器。c程序通过调用malloc函数来分配块，通过调用free函数来释放块。C++中的new和delete调用是可以比较的。

Implicit allocators, on the other hand, require the allocator to detect when an allocated block is no longer being used by the program and then free the block. Implicit allocators are also known as garbage collectors, and the process of automatically freeing unused allocated blocks is known as garbage collection. For example, higher-level languages such as Lisp, ML, and Java rely on garbage collection to free allocated blocks.

另一方面，隐式分配器要求分配器检测程序何时不再使用已分配的块，然后释放该块。隐式分配器也称为垃圾收集器，自动释放未使用的已分配块的过程称为垃圾收集。例如，Lisp、ML和Java等高级语言依靠垃圾收集来释放分配的块。

The remainder of this section discusses the design and implementation of explicit allocators. We will discuss implicit allocators in Section 9.10 . For concrete -ness, our discussion focuses on allocators that manage heap memory. However, you should be aware that memory allocation is a general idea that arises in a variety of contexts. For example, applications that do intensive manipulation of graphs will often use the standard allocator to acquire a large block of virtual memory and then use an application-specific allocator to manage the memory within that block as the nodes of the graph are created and destroyed.

本节的剩余部分将讨论显式分配器的设计和实现。我们将在9.10节讨论隐式分配器。具体来说，我们的讨论集中在管理堆内存的分配器上。但是，您应该意识到内存分配是一个在各种环境中出现的一般概念。例如，对图形进行密集操作的应用程序通常会使用标准分配器来获取一大块虚拟内存，然后在创建和销毁图形节点时，使用特定于应用程序的分配器来管理该块内存。

### 9.9.1 The malloc and free Functions

The C standard library provides an explicit allocator known as the malloc package. Programs allocate blocks from the heap by calling the malloc function.

C标准库提供了一个显式的分配器，称为malloc包。程序通过调用malloc函数从堆中分配块。

Aside How big is a word? Recall from our discussion of machine code in Chapter 3 that Intel refers to 4-byte objects as double words. However, throughout this section, we will assume that words are 4-byte objects and that double words are 8-byte objects, which is consistent with conventional terminology.

一个词有多大?回想一下我们在第3章中对机器代码的讨论，Intel将4字节对象称为双字。然而，在本节中，我们将假设单词是4字节的对象，双单词是8字节的对象，这与传统术语是一致的。

The malloc function returns a pointer to a block of memory of at least size bytes that is suitably aligned for any kind of data object that might be contained in the block. In practice, the alignment depends on whether the code is compiled to run in 32-bit mode ( gcc –m32 ) or 64bit mode (the default). In 32-bit mode, malloc returns a block whose address is always a multiple of 8. In 64-bit mode, the address is always a multiple of 16.

malloc 函数返回一个指向内存块的指针，该内存块至少为 size 字节，该内存块针对可能包含在该块中的任何类型的数据对象进行了适当对齐。实际上，对齐方式取决于代码是编译为在 32 位模式（ gcc –m32 ）还是 64 位模式（默认）下运行。在 32 位模式下，malloc 返回一个地址始终是 8 的倍数的块。在 64 位模式下，地址始终是 16 的倍数。

If malloc encounters a problem (e.g., the program requests a block of memory that is larger than the available virtual memory), then it returns NULL and sets errno . Malloc does not initialize the memory it returns. Applications that want initialized dynamic memory can use calloc , a thin wrapper around the malloc function that initializes the allocated memory to zero . Applications that want to change the size of a previously allocated block can use the realloc function.

如果 malloc 遇到问题（例如，程序请求的内存块大于可用的虚拟内存），则它返回 NULL 并设置 errno 。 Malloc 不会初始化它返回的内存。需要初始化动态内存的应用程序可以使用 calloc，它是 malloc 函数的一个瘦包装器，可将分配的内存初始化为零。想要更改先前分配的块大小的应用程序可以使用 realloc 函数。

Dynamic memory allocators such as malloc can allocate or deallocate heap memory explicitly by using the mmap and munmap functions, or they can use the sbrk function:

动态内存分配器（例如 malloc）可以使用 mmap 和 munmap 函数显式分配或取消分配堆内存，也可以使用 sbrk 函数：

The sbrk function grows or shrinks the heap by adding incr to the kernel's brk pointer. If successful, it returns the old value of brk , otherwise it returns –1 and sets errno to ENOMEM. If incr is zero, then sbrk returns the current value of brk . Calling sbrk with a negative incr is legal but tricky because the return value (the old value of brk ) points to abs (incr) bytes past the new top of the heap.

sbrk函数通过向内核的brk指针添加incr来增加或减少堆。如果成功，它返回原来的brk值，否则返回-1并将errno设置为ENOMEM。如果incr为零，则sbrk返回brk的当前值。使用负的incr调用sbrk是合法的，但需要技巧，因为返回值(brk的旧值)指向堆新顶部之后的abs (incr)字节。

Programs free allocated heap blocks by calling the free function.

程序通过调用free函数来释放已分配的堆块。

The ptr argument must point to the beginning of an allocated block that was obtained from malloc, calloc , or realloc . If not, then the behavior of free is undefined. Even worse, since it returns nothing, free gives no indication to the application that something is wrong. As we shall see in Section 9.11 , this can produce some baffling run-time errors.

ptr参数必须指向从malloc、calloc或realloc获得的已分配块的开头。如果不是，那么自由的行为是未定义的。更糟糕的是，由于它不返回任何东西，free没有向应用程序提示哪里出了问题。正如我们将在第9.11节中看到的，这可能会产生一些令人困惑的运行时错误。

Figure 9.34 Allocating and freeing blocks with malloc and free . Each square corresponds to a word. Each heavy rectangle corresponds to a block. Allocated blocks are shaded. Padded regions of allocated blocks are shaded with a darker blue. Free blocks are unshaded. Heap addresses increase from left to right.

图9.34使用Malloc和FREE来分配和释放块。每个方块对应一个单词。每个较大的矩形对应一个块。已分配的块显示为阴影。已分配块的填充区域用较深的蓝色阴影。可用块未加阴影。堆地址从左到右递增。

Figure 9.34 shows how an implementation of malloc and free might manage a (very) small heap of 16 words for a C program. Each box represents a 4-byte word. The heavy-lined rectangles correspond to allocated blocks (shaded) and free blocks (unshaded). Initially, the heap consists of a single 16-word double-word-aligned free block.

图9.34显示了Malloc和Free的实现如何管理一个C程序的(非常)16个单词的小堆。每个框代表一个4字节字。粗线矩形对应于已分配块(带阴影)和空闲块(未带阴影)。最初，堆由一个16字、双字对齐的空闲块组成。

1. Throughout this section, we will assume that the allocator returns blocks aligned to 8-byte double-word boundaries

1.在本节中，我们假设分配器返回与8字节双字边界对齐的块

Figure 9.34(a) . The program asks for a four-word block. Malloc responds by carving out a four-word block from the front of the free block and returning a pointer to the first word of the block.

图9.34(A)。该程序要求四个字的区块。Malloc的响应是从空闲块的前面切出一个四字块，并返回指向该块第一个字的指针。

Figure 9.34(b) . The program requests a five-word block. Malloc responds by allocating a six-word block from the front of the free block. In this example, malloc pads the block with an extra word in order to keep the free block aligned on a double-word boundary

图9.34(B)。该程序要求一个五字块。Malloc的响应是从空闲块的前面分配一个六字块。在本例中，为了使空闲块在双字边界上对齐，Malloc用一个额外的字填充块

Figure 9.34(c) . The program requests a six-word block and malloc responds by carving out a six-word block from the free block.

图9.34(C)。程序请求一个六字的块，而Malloc的响应是从空闲块中切出一个六字的块。

Figure 9.34(d) . The program frees the six-word block that was allocated in Figure 9.34(b) . Notice that after the call to free returns, the pointer p2 still points to the freed block. It is the responsibility of the application not to use p2 again until it is reinitialized by a new call to malloc .

图9.34(D)。该程序释放了图9.34(B)中分配的六字块。注意，在对Free的调用返回之后，指针p2仍然指向freed块。在通过对Malloc的新调用重新初始化P2之前，应用程序有责任不再使用P2。

Figure 9.34(e) . The program requests a two-word block. In this case, malloc allocates a portion of the block that was freed in the previous step and returns a pointer to this new block.

图9.34(E)。该程序请求一个两个字的块。在这种情况下，Malloc分配在上一步中释放的块的一部分，并返回指向这个新块的指针。

### 9.9.2 Why Dynamic Memory Allocation?

The most important reason that programs use dynamic memory allocation is that often they do not know the sizes of certain data structures until the program actually runs. For example, suppose we are asked to write a C program that reads a list of n ASCII integers, one integer per line, from stdin into a C array. The input consists of the integer n, followed by the n integers to be read and stored into the array. The simplest approach is to define the array statically with some hard-coded maximum array size:

程序使用动态内存分配的最重要原因是，在程序实际运行之前，它们通常不知道某些数据结构的大小。例如，假设我们被要求编写一个C程序，从stdin读入一个包含n个ASCII整数的列表，每行一个整数。输入包括整数n，后跟要读取并存储到数组中的n个整数。最简单的方法是用一些硬编码的最大数组大小静态定义数组:

Allocating arrays with hard-coded sizes like this is often a bad idea. The value of MAXN is arbitrary and has no relation to the actual amount of available virtual memory on the machine. Further, if the user of this program wanted to read a file that was larger than MAXN, the only recourse would be to recompile the program with a larger value of MAXN. While not a problem for this simple example, the presence of hard-coded array bounds can become a maintenance nightmare for large software products with millions of lines of code and numerous users.

像这样分配具有硬编码大小的数组通常不是一个好主意。MAXN的值是任意的，与机器上可用虚拟内存的实际数量无关。而且，如果该程序的用户想要读取大于MAXN的文件，惟一的办法就是用更大的MAXN值重新编译该程序。虽然对于这个简单的示例来说不是问题，但硬编码的数组边界的存在可能成为拥有数百万行代码和众多用户的大型软件产品的维护噩梦。

A better approach is to allocate the array dynamically, at run time, after the value of n becomes known. With this approach, the maximum size of the array is limited only by the amount of available virtual memory.

更好的方法是在运行时，在n的值已知之后动态分配数组。使用这种方法，数组的最大大小仅受可用虚拟内存数量的限制。

Dynamic memory allocation is a useful and important programming technique. However, in order to use allocators correctly and efficiently, programmers need to have an understanding of how they work. We will discuss some of the gruesome errors that can result from the improper use of allocators in Section 9.11 .

动态内存分配是一种有用且重要的编程技术。然而，为了正确有效地使用分配器，程序员需要了解它们是如何工作的。在第9.11节中，我们将讨论一些由于不恰当地使用分配器而导致的可怕错误。

### 9.9.3 Allocator Requirements and Goals

Explicit allocators must operate within some rather stringent constraints:

显式分配器必须在一些相当严格的约束下操作:

Handling arbitrary request sequences. An application can make an arbitrary sequence of allocate and free requests, subject to the constraint that each free request must correspond to a currently allocated block obtained from a previous allocate request. Thus, the allocator cannot make any assumptions about the ordering of allocate and free requests. For example, the allocator cannot assume that all allocate requests are accompanied by a matching free request, or that matching allocate and free requests are nested.

处理任意请求序列。应用程序可以发出任意序列的分配和释放请求，受制于每个释放请求必须对应于从先前分配请求获得的当前分配块的约束。因此，分配器不能对分配和释放请求的顺序做出任何假设。例如，分配器不能假设所有的分配请求都伴随着一个匹配的空闲请求，或者匹配的分配和空闲请求是嵌套的。

Making immediate responses to requests. The allocator must respond immediately to allocate requests. Thus, the allocator is not allowed to reorder or buffer requests in order to improve performance.

立即响应请求。分配器必须立即响应分配请求。因此，分配器不允许重新排序或缓冲请求以提高性能。

Using only the heap. In order for the allocator to be scalable, any nonscalar data structures used by the allocator must be stored in the heap itself.

只使用堆。为了使分配器可伸缩，分配器使用的任何非标量数据结构都必须存储在堆本身中。

Aligning blocks (alignment requirement). The allocator must align blocks in such a way that they can hold any type of data object.

对齐块（对齐要求）。分配器必须对齐块，以便它们可以容纳任何类型的数据对象。

Not modifying allocated blocks. Allocators can only manipulate or change free blocks. In particular, they are not allowed to modify or move blocks once they are allocated. Thus, techniques such as compaction of allocated blocks are not permitted.

不修改分配的块。分配器只能操作或更改空闲块。特别是，一旦分配了块，就不允许它们修改或移动块。因此，不允许使用诸如压缩分配块的技术。

Working within these constraints, the author of an allocator attempts to meet the often conflicting performance goals of maximizing throughput and memory utilization.

在这些限制条件下，分配器的作者试图满足经常相互冲突的性能目标，即最大化吞吐量和内存利用率。

Goal 1: Maximizing throughput. Given some sequence of n allocate and free requests

目标 1：最大化吞吐量。给定一些 n 分配和释放请求的序列

we would like to maximize an allocator's throughput, which is defined as the number of requests that it completes per unit time. For example, if an allocator completes 500 allocate requests and 500 free requests in 1 second, then its throughput is 1,000 operations per second. In general, we can maximize throughput by minimizing the average time to satisfy allocate and free requests. As we'll see, it is not too difficult to develop allocators with reasonably good performance where the worst-case running time of an allocate request is linear in the number of free blocks and the running time of a free request is constant.

我们希望最大化分配器的吞吐量，其定义为单位时间内完成的请求数。例如，如果一个分配器在1秒内完成500个分配请求和500个空闲请求，则其吞吐量为每秒1,000个操作。通常，我们可以通过最小化满足分配和释放请求的平均时间来最大化吞吐量。正如我们将看到的，开发具有相当好的性能的分配器并不是太困难，其中分配请求的最坏情况下的运行时间与空闲块的数量成线性关系，而空闲请求的运行时间是恒定的。

Goal 2: Maximizing memory utilization. Naive programmers often incorrectly assume that virtual memory is an unlimited resource. In fact, the total amount of virtual memory allocated by all of the  processes in a system is limited by the amount of swap space on disk. Good programmers know that virtual memory is a finite resource that must be used efficiently. This is especially true for a dynamic memory allocator that might be asked to allocate and free large blocks of memory.

目标2：最大限度地提高内存利用率。天真的程序员经常错误地认为虚拟内存是一种无限的资源。事实上，系统中所有进程分配的虚拟内存总量受磁盘上的交换空间量的限制。优秀的程序员知道，虚拟内存是一种有限的资源，必须得到有效利用。对于可能被要求分配和释放大量内存块的动态内存分配器而言，情况尤其如此。

There are a number of ways to characterize how efficiently an allocator uses the heap. In our experience, the most useful metric is peak utilization. As before, we are given some sequence of n allocate and free requests

有许多方法可以表征分配器使用堆的效率。根据我们的经验，最有用的指标是峰值利用率。与前面一样，我们得到n个分配请求和空闲请求的一些序列

The objective of the allocator, then, is to maximize the peak utilization U over the entire sequence. As we will see, there is a tension between maximizing throughput and utilization. In particular, it is easy to write an allocator that maximizes throughput at the expense of heap utilization. One of the interesting challenges in any allocator design is finding an appropriate balance between the two goals.

因此，分配器的目标是最大化整个序列上的峰值利用率U。正如我们将看到的，在最大化吞吐量和利用率之间存在着矛盾。特别是，很容易编写一个以牺牲堆利用率为代价来最大化吞吐量的分配器。在任何分配器设计中，一个有趣的挑战是在这两个目标之间找到适当的平衡。

