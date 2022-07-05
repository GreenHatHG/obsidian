# Resource Management

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

## 