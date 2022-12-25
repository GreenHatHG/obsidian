# Big Three

- big three：copy constructor、copy assignment operator、destructor

```c++
#include <cstring>

class String{
public:
    String (const char* cstr = nullptr);
    String (const String& str);
    String& operator = (const String& str);
    ~String();
    char* get_c_str() const {return m_data;};
private:
    char* m_data;
};

inline String::String(const char* cstr){
    if(cstr){
        m_data = new char[strlen(cstr)+1];
        strcpy(m_data, cstr);
    }else{
        // 未指定初值
        m_data = new char[1];
        *m_data = '\0';
    }
}

inline String::String(const String& str){
    m_data = new char[strlen(str.m_data)+1]; //friend
    strcpy(m_data, str.m_data);
}

inline String::~String(){
    delete[] m_data;
}

inline String& String::operator=(const String &str) {
    // self assignment
    if (this == &str){
        return *this;
    }
    delete[] m_data;
    m_data = new char[strlen(str.m_data)+1];
    strcpy(m_data, str.m_data);
    return *this;
}

std::ostream& operator << (std::ostream& os, const String& str){
    return os << str.get_c_str();
}

int main(){
    String s1;
    String s2("hello"); //自动调用析构函数
    String s3(s2); //copy constructor
    s1 = s2; // copy assignment operator

    std::cout << "s1:" << s1 << std::endl;
    std::cout << "s2:" << s2 << std::endl;

    auto* p = new String("Hello");
    delete p;
}
```

![](Big-Three/20221224143034-167198711162011.png)

# Stack and Heap

scope: 函数作用域

![061](Big-Three/061-167198711162014.jpg)

![](Big-Three/20221224152050-167198711162013.png)

![](Big-Three/20221224152227-167198711162012.png)