- Templates are a compile-time mechanism, so their use incurs **no run-time overhead** compared to hand-crafted code(*手工编写的*).

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
template <typename Collection, typename DataType>
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
template <typename InputIterator, typename DataType>
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

```c++
template <typename InputIterator, typename UniaryPredicate>
int countVal(InputIterator begin, InputIterator end, UniaryPredicate predicate){
    int count = 0;
    for(auto iter = begin; iter != end; ++iter){
        if(predicate(*iter)) ++count;
    }
    return  count;
}

bool isLessThan5(int val){
    return val < 5;
}

int main(){
    std::vector<int> v{1,2,3,4,5,6,7,8,1};
    std::cout << countVal(v.begin(), v.end(), isLessThan5) << std::endl;
}
```

```c++
template <typename InputIterator, typename UniaryPredicate>
int countVal(InputIterator begin, InputIterator end, UniaryPredicate predicate){
    int count = 0;
    for(auto iter = begin; iter != end; ++iter){
        if(predicate(*iter)) ++count;
    }
    return  count;
}

int main(){
    std::vector<int> v{1,2,3,4,5,6,7,8,1};
    int limit = 5;
    auto isLessThanLimit = [limit](auto val)->bool{
        return val < limit;
    };
    std::cout << countVal(v.begin(), v.end(), isLessThanLimit) << std::endl;
}
```

