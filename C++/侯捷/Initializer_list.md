```c++
#include <iostream>

template<typename T>
void print(std::initializer_list<T> vals){
    for(auto x: vals){
        std::cout << x << std::endl;
    }
}

int main(){
    print({1,2,3,4,5,7});
    print({"a", "b"});
}
```

initializer_list只是个常量数组，分配的数据在栈，vector则是动态分配在堆