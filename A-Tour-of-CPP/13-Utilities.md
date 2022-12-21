# Resource Management

## Lifetime

- **Global objects** are allocated at program start-up and destroyed when the program ends. 
- **Local, automatic objects** are created and destroyed when the block in which they are defined is entered and exited. 
- **Local static objects** are allocated before their first use and are destroyed when the program ends.

## Memory

- Our programs have used only **static or stack memory**. 
  - **Static memory** is used for **local static objects**, for **class static data members**, and for **variables defined outside any function**. 
  - **Stack memory** is used for **nonstatic objects defined inside functions**.

- In addition to static or stack memory, every program also has a **pool of memory** that it can use. 
  - This memory is referred to as the **free store or heap**. 
  - Programs use the **heap** for objects that they **dynamically allocate**—that is, for objects that **the program allocates at run time**. 
  - The program controls the lifetime of dynamic objects; our code must explicitly destroy such objects when they are no longer needed.


## RAII

[c++ - What is meant by Resource Acquisition is Initialization (RAII)? - Stack Overflow](https://stackoverflow.com/questions/2321511/what-is-meant-by-resource-acquisition-is-initialization-raii)

```c++
RawResourceHandle* handle=createNewResource();
handle->performInvalidOperation();  // Oops, throws exception
...
deleteResource(handle); // oh dear, never gets called so the resource leaks
```

With the RAII one

```c++
class ManagedResourceHandle {
public:
   ManagedResourceHandle(RawResourceHandle* rawHandle_) : rawHandle(rawHandle_) {};
   ~ManagedResourceHandle() {delete rawHandle; }
   ... // omitted operator*, etc
private:
   RawResourceHandle* rawHandle;
};
```

```c++
ManagedResourceHandle handle(createNewResource());
handle->performInvalidOperation();
```

其实就是把释放动作放到析构函数里面，当超过变量作用域时候会自动释放
