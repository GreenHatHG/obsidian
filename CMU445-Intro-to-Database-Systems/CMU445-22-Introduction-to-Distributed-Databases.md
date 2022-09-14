#  System Architectures

![21-distributed_11](CMU445-22-Introduction-to-Distributed-Databases/21-distributed_11.JPG)

A single-node DBMS uses what is called a **shared everything** architecture. 

This single node executes workers on a local CPU(s) with its own local memory address space and disk. 

## Shared Memory

An alternative to shared everything architecture in distributed systems is shared memory. 

CPUs have access to common memory address space via a fast interconnect. CPUs also share the same disk.

In practice, most DBMSs do not use this architecture, as it is provided at the OS / kernel level. It also causes problems, since each process’s scope of memory is the same memory address space, which can be modified by multiple processes.

Each processor has a global view of all the in-memory data structures. Each DBMS instance on a processor has to “know” about the other instances.

## Shared Disk



