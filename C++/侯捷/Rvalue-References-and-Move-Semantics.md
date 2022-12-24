- Rvalue被move之后就不能再使用了
  - 一般情况下temp object不会继续用到，所以编译器看到temp object一定当作Rvalue
  - 如果Lvalue明确不会继续用到，可以显式指定

Unperfect Forwarding

函数调用传递过程中可能会丢失一些信息，比如insert会调用insert(&&)再到move constructor

 