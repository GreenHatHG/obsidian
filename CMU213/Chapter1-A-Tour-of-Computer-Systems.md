[15-213: Introduction to Computer Systems / Schedule Fall 2015 (cmu.edu)](https://www.cs.cmu.edu/afs/cs/academic/class/15213-f15/www/schedule.html)
# Memory Referencing Bug
```c++
#include <stdio.h>  
  
typedef struct {  
    int a[2];  
    double d;  
} struct_t;  
  
double fun(int i) {  
    struct_t s;  
    s.d = 3.14;  
    s.a[i] = 1073741824; /* Possibly out of bounds */  
 return s.d;  
}  
  
int main() {  
    for(int i = 0; i < 10; i++){  
        printf("fun(%d): %lf\n", i, fun(i));  
    }  
    return 0;  
}

/*
output:
fun(0)  3.14
fun(1)  3.14
fun(2)  3.1399998664856
fun(3)  2.00000061035156
fun(4)  3.14
fun(6)  Segmentation fault
*/
```
没有改变s.d的值，但是s.d的值也会发生改变
这个和数据如何在内存中布局和访问有关，c/c++一个特性是在运行时不会边界检查，但是操作系统就会检查。
![[Pasted image 20220409232257.png]]
每个block代表4个字节（64位一个int类型变量占用4个字节），如果修改`a[2]`，实际上修改的是变量d的内存，所以会看到错乱的数字出现。继续越界到达某个点的时候，该程序的一些状态被修改了，该状态用于维持程序运行，最有可能是跟踪已经分配的内存，这就造成了程序崩溃。
# Memory System Performance
![[Pasted image 20220410183701.png]]
逐行访问的方式比按列访问的方式要好的多，二维数组每个数组元素在分配空间的时候是一段连续内存，按列访问就是在跨度很大的地址间跳来跳去。
