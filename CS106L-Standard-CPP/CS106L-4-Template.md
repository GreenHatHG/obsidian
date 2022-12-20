```c++
template <typename T>
bool test(T a, T b){
    return a > b;
}

int main(){
    test<int>(1, 2);
    test('a', 'b');
}
```

```c++
template <class Collection, typename DataType>
int countVal(const Collection& list, DataType val){
    int count = 0;
    for(auto iter = list.begin(); iter != list.end(); ++iter){
        if(*iter == val) ++count;
    }
    return  count;
}

int main(){
    std::cout << countVal<std::vector<int>>({1,2,3,1}, 1);
}
```

上面假定了是遍历所有的容器，可以更自由点

```c++
template <class InputIterator, typename DataType>
int countVal(InputIterator begin, InputIterator end, DataType val){
    int count = 0;
    for(auto iter = begin; iter != end; ++iter){
        if(*iter == val) ++count;
    }
    return  count;
}

int main(){
    std::vector<int> v{1,2,3,4,5,6,7,8,1};
    std::cout << countVal(v.begin(), v.end(), 1) << std::endl;

    std::cout << countVal(v.begin()+int(v.size())/2, v.end(), 1) << std::endl;
}
```

