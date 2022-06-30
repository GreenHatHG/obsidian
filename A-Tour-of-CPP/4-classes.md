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