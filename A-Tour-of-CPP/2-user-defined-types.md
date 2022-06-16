# Class

There is no fundamental(*根本的*) difference between a struct and a class; **a struct is simply a class with members public by default**. For example, you can define constructors and other member functions for a struct.

# Enumerations

```c++
enum class Color { red, blue , green };
enum class Traffic_light { green, yellow, red };

Color col = Color::red;
Traffic_light light = Traffic_light::red;

Color x = Color{5}; // OK, but verbose
Color y {6}; // also OK
```

By default, an enum class has only assignment, initialization, and comparisons (e.g., == and <) defined. However, an enumeration is a user-defined type, so we can define operators for it.

```c++
Traffic_light &operator++(Traffic_light & t)	// prefix increment: ++
{
	switch (t){
		case Traffic_light::green:
			return t = Traffic_light::yellow;
		case Traffic_light::yellow:
			return t = Traffic_light::red;
		case Traffic_light::red:
			return t = Traffic_light::green;
	}
}

Traffic_light next = ++light;	// next becomes T raffic_light::green
```

