# Separate Compilation

C++ supports a notion of separate compilation where user code sees only declarations of the types and functions used. 

The definitions of those types and functions are in separate source files and are compiled separately. 

Such separation can be used to minimize(*最大限度减少*) compilation times and to strictly enforce(*严格保证*) separation of logically distinct parts of a program (thus minimizing the chance(*可能性*) of errors). A library is often a collection of separately compiled code fragments (e.g., functions)(*单独编译的代码片段的集合*).

通常，我们将特定模块接口的声明放在一个文件中，该文件的名称表明其预期用途

```c++
// Vector.h:
class Vector{
	public:
		Vector(int s);
	    double &operator[](int i);
	    int size();
	private:
		double∗ elem;	// elem points to an array of sz doubles
	    int sz;
};
```

This declaration would be placed in a file `Vector.h`. Users then include that file, called a **header file**, to access that interface.

```c++
// user.cpp:
#include "Vector.h"	// get Vector’s interface
#include <cmath>	// get the standard-librar y math function interface including sqrt()

double sqrt_sum(Vector & v) 
{
	double sum = 0;
	for (int i = 0; i != v.size(); ++i)
		sum += std::sqrt(v[i]);	// sum of square roots
	return sum;
}
```

To help the compiler ensure consistency, the `.cpp` file providing the implementation of `Vector` will also include the `.h` file providing its interface:

```c++
// Vector.cpp:
#include "Vector.h"	// get Vector’s interface

Vector::Vector(int s)
    :elem{new double[s]}, sz{s}	// initialize members
{
}

double &Vector::operator[](int i)
{
	return elem[i];
}

int Vector::siz e()
{
	return sz;
}
```

# Error Handling

```c++
double& Vector::operator[](int i)
{
    if (i<0 || size()<=i)
        throw out_of_rang e{"Vector::operator[]"};
    return elem[i];
}
```

The `out_of_range` type is defined in the standard library (in `<stdexecpt>`) and is in fact used by some standard-library container access functions. （*一些标准库的access函数也在使用*）

```c++
void f(Vector& v)
{
    // ...
    try { // exceptions here are handled by the handler defined below

        v[v.siz e()] = 7; // tr y to access beyond the end of v
    }
    catch (out_of_rang e& err) { // oops: out_of_range error
        // ... handle range error ...
        cerr << err.what() << '\n';
    }
    // ...
}
```

# Value Return

a local variable disappears when the function returns, so we should not
return a pointer or reference to it:

```c++
int& bad()
{
    int x;
    // ...
    return x; // bad: return a reference to the local var iable x
}
```

Fortunately, all major C++ compilers will catch the obvious error in ``bad()`.

How do we pass large amounts of information out of a function:

```c++
Matrix operator+(const Matrix& x, const Matrix& y)
{
    Matrix res;
    // ... for all res[i,j], res[i,j] = x[i,j]+y[i,j] ...
    return res;
}

Matrix m1, m2;
// ...
Matrix m3 = m1+m2; // no copy
```

Returning large objects by returning a pointer to it is common in older code and a major source of hard-to-find errors. Don’t write such code. 

```c++
Matrix∗ add(const Matrix& x, const Matrix& y) // complicated and error-prone 20th century style
{
    Matrix∗ p = new Matrix;
    // ... for all *p[i,j], *p[i,j] = x[i,j]+y[i,j] ...
    return p;
}

Matrix m1, m2;
// ...
Matrix∗ m3 = add(m1,m2); // just copy a pointer
// ...
delete m3; // easily forgotten
```

Note that `operator+()` is as efficient as `add()`, but far easier to define, easier to use, and less error-prone(*易于出错的*).

https://en.wikipedia.org/wiki/Copy_elision

