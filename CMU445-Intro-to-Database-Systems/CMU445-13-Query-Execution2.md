# Process Models

The DBMS is comprised of more or more `workers` that are responsible for executing tasks on behalf of the client and returning the results. （worker可以是一个进程也可以是一个线程）

## Process per Worker

每个进程上有同一个page的副本，浪费内存，解决方法是使用共享内存，OS提供了支持。

好处是如果代码有bug进程崩溃了，不至于整个系统都崩溃。

老系统(1970)使用了这种方案：IBM DB2,Postgres,Oracle。即使当时已经出现了线程，但是没有标准的api，有各种OS，不好扩展DB到不同的OS，但是每个OS都有fork和join。

