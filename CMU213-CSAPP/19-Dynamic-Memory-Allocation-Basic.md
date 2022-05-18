# 19-Dynamic-Memory-Allocation-Basic

We can use the low-level mmap and munmap functions to create and delete areas of virtual memory, but using **dynamic memory allocators** (such as malloc) to acquire VM at run time is more convenient and portable(*可移植的*).

A dynamic memory allocator maintains an area of a process's virtual memory known as the **heap**.

<img src="19-Dynamic-Memory-Allocation-Basic/19-malloc-basic_3.JPG" width="50%">

An allocator maintains the heap as **a collection of various-size blocks**. Each block is a contiguous chunk of virtual memory that is either **allocated** or **free**.

Types of allocators:

- **Explicit(*显式*) allocator**: application allocates and frees space. E.g., malloc and free in C.
- **Implicit allocator**: application allocates, but does not free space. E.g. garbage collection in Java, ML, and Lisp.

## Explicit allocator

### The malloc Package

