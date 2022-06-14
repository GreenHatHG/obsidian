# Initialization

```c++
double d1 = 2.3;//initialize d1 to 2.3
double d2 {2.3};//initialize d2 to 2.3
double d3 = {2.3};//initialize d3 to 2.3 (the = is optional with { ... })
vector<int> v {1,2,3,4,5,6};//a vector of ints
```

`{}` can save(*避免*) you from conversions that lose information.

```c++
int i1 = 7.8;   //i1 becomes 7
int i2 {7.8};   //error : floating-point to integer conversion
```

With `auto`, we tend to(*倾向于*) use the `=` because there is no potentially troublesome(*潜在的麻烦*) type conversioninvolved, but if you prefer to use `{}` initialization consistently(*一贯地*), you can do that instead.

```c++
auto bb {true};
auto i = 123;
```

# Constants

- `const`: The value of a const can be calculated at run time.
- `constexpr`: This is used primarily to specify constants, to allow placement of data in read-only memory and for performance. The value of a constexpr must be calculated by the compiler.

```c++
constexpr int dmv = 17; // dmv is a named constant
int var = 17; // var is not a constant
const double sqv = sqrt(var); // sqv is a named constant, possibly computed at run time

double sum(const vector<double>&); // sum will not modify its argument (§1.7)

vector<double> v {1.2, 3.4, 4.5}; // v is not a constant
const double s1 = sum(v); // OK: sum(v) is evaluated at run time
constexpr double s2 = sum(v); // error : sum(v) is not a constant expression
```

# Reference

```c++
void increment()
{
    int v[] = {0,1,2,3,4,5,6,7,8,9};

    for (auto& x : v) // add 1 to each x in v
        ++x;
    // ...
}
```

`&` means "reference to". A reference is similar to a pointer,except that you don’t need to use a prefix `*` to access the value referred to by the reference. Also, a reference cannot be made to refer to a different object after its initialization.

```c++
T& r //T&: r is a reference to T
```

There is no "null reference". A reference must refer to a valid object.

# The Null Pointer

using `nullptr` eliminates potential confusion(*消除了潜在的混淆*) between integers (such as 0 or NULL) and pointers (such as nullptr).

```c++
int count_x(const char* p, char x)
    // count the number of occurrences of x in p[]
    // p is assumed to point to a zero-ter minated array of char (or to nothing)
{
    if (p==nullptr)
        return 0;
    int count = 0;
    while (*p) {
        if (*p==x)
            ++count;
        ++p;
    }
    return count;
}
```

# If

```c++
void do_something(vector<int>& v)
{
    if (auto n = v.size(); n!=0) {
        // ... we get here if n!=0 ...
    }
    // ...
}
```

更简洁可以写成`if (auto n = v.size())`

