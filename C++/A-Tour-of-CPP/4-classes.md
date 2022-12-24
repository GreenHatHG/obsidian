# Abstract Types

```c++
class Container {
public:
  virtual double &operator[](int) = 0; // pure virtual function
  virtual int size() const = 0;        // const member function
  virtual ˜Container() {}              // destructor
};
```

The word `virtual` means "may be redefined later in a class derived(*派生*) from this one." The `curious=0` syntax says the function is pure virtual; that is, some class derived from `Container` must define the function.

```c++
Container c; // error : there can be no objects of an abstract class
Container∗ p = new Vector_container(10); // OK: Container is an interface
```

```c++
// Vector_container implements Container
class Vector_container: public Container {
public:
  Vector_container(int s) : v(s) {} // Vector of s elements
  ˜Vector_container() {}
  double &operator[](int i) override { return v[i]; }
  int size() const override { return v.siz e(); }

private:
  Vector v;
};
```

The use of `override` is optional, but being explicit(*显式*) allows the compiler to catch mistakes, such as misspellings(*拼写错误*) of function names or slight differences(*细微的区别*) between the type of a virtual function and its intended overrider.

The member destructor (`˜Vector()`) is implicitly(*隐式*) invoked by its class’s destructor (`˜Vector_container()`).

