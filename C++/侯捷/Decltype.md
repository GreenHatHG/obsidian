# Metaprogramming

```c++
#include <iostream>
#include <vector>

template<typename T>
void test(T obj){
    // obj设计传入是一个容器,可以取到iterator
    // 这里是为了取出类型typedef，所以需要添加个typename关键字告诉编译器说是个类型
    typedef typename decltype(obj)::iterator iType1;
    typedef typename T::iterator iType2;
    decltype(obj) anotherObj(obj);
}

int main(){
    test(std::vector<int>{});
}
```

