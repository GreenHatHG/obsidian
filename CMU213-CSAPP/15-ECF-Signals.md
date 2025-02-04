# 15-ECF:Signals

## Shells

![png](15-ECF-Signals/15-ecf-signals_4.JPG)

在Linux上创建进程一种方法，使用fork调用。系统上的所有进程形成了一个层次结构，启动系统时创建的第一个进程是PID为1的init进程，系统上的所有其他进程都是init进程的后代。

init 进程在启动时会创建守护进程(daemon)，这些守护进程通常是提供服务的长期运行程序。并且会创建login shell为用户提供命令行界面。shell会在子进程中执行命令，并且该子进程可能也会创建其他子进程。

### Shell Programs

![png](15-ECF-Signals/15-ecf-signals_5.JPG)

在shell中，执行(execution)包含了一系列读取和解析命令行的步骤。

### Simple Shell eval Function

![png](15-ECF-Signals/15-ecf-signals_6.JPG)

parseline用于解析命令行，命令解析到argv数组。

bg代表命令是否以`&`结束，如果有，那么该命令将会后台运行(background job)，这意味着shell不会等待该任务完成，即在它完成之前，它会进行下一个读取步骤。如果没有，需要shell前台运行命令(foreground job)，意味着shell需要等待命令执行完成。

shell实现了内置命令(built-in command)，比如jobs(显示当前系统任务列表)、bg、fg(前台运行)，都是shell自身实现。

如果不是内置命令，shell会fork出一个子进程，该子进程会通过调用execve来执行这个程序。execve没有错误情况下不会return，出现了错误会exit，所以子进程不会继续往下执行。

前台job和后台job之间的唯一区别就是shell是否对该job执行waitpid。

#### Problem with Simple Shell Example

可以看到对于前台job有waitpid reap子进程没有问题，但是后台job会造成以下影响：

1. shell终止后子进程会变成僵尸进程，永远不会被reaped。
2. 造成内存泄漏导致内核耗尽内存。

Exceptional control flow可以解决这个问题：内核将在其任何子进程终止时通知shell，然后shell可以对此做出反应并调用waitpid。在Unix中这种机制称为信号(signal)。

## Signals

A signal is a small message that notifies a process that an event of some type has occurred in the system.

- 类似于exceptions和interrupts
- 信号总是从内核发送的，有时另一个进程会要求内核向其他进程发送消息。
- 信号中包含的唯一信息是唯一的整数id（1~30）

![png](15-ECF-Signals/15-ecf-signals_10.JPG)

- SIGINT和SIGKILL都是终止进程，但是后者是无法忽略或者被覆盖。

- SIGSEGV是最常见的分段错误，即分段违规(Segmentation violation)，如果访问受保护或不合法的内存区域，内核将向你的进程发送一个SIGSEGV信号。

- SIGALRM用于将信号发送给程序自己，可以用作timer功能。

- SIGCHLD：每当进程它的一个子进程停止或者终止时候，内核会给父进程一个该信号。

### Signal Concepts: Sending a Signal

Kernel **sends** (delivers) a signal to a **destination process** by updating some state in the context of the destination process.除了目标进程上下文中的某些bit位发生变化之外什么都不会发生。

Kernel sends a signal for one of the following reasons:

- Kernel has detected a system event such as divide-by-zero (SIGFPE) or the termination of a child process (SIGCHLD).
- Another process has invoked the **kill system call**(只是方式之一) to explicitly request the kernel to send a signal to the destination process.

### Signal Concepts: Receiving a Signal

A destination process receives a signal when it is forced by the kernel to react in some way to the delivery of the signal.

Some possible ways to react:

- **Ignore** the signal (do nothing)
- **Terminate** the process (with optional core dump)
- **Catch** the signal by executing a user-level function called **signal handler**.类似于asynchronous exception handler，只不过一个是发生在内核，一个是发生在C代码。

![png](15-ECF-Signals/15-ecf-signals_12.JPG)

### Signal Concepts: Pending and Blocked Signals

A signal is **pending** if sent but not yet received

- There can be at most one pending signal of any particular type
  - Important: Signals are not queued
  - If a process has a pending signal of type k, then subsequent signals of type k that are sent to that process are discarded
- A process can **block** the receipt of certain(*一些*)signals
  - Blocked signals can be delivered, but will not be received until the signal is unblocked
- A pending signal is received at most once

### Signal Concepts: Pending/Blocked Bits

 Kernel maintains pending and blocked bit vectors in the context of each process.每个bit对应于某个特定信号，这就是为什么不是queued的原因。当我们传递一个信号的时候，内核会设置那个bit。

- pending: represents the set of pending signals
  - Kernel sets bit k in pending when a signal of type k is delivered
  - Kernel clears bit k in pending when a signal of type k is received
- blocked: represents the set of blocked signals
  - Can be set and cleared by using the `sigprocmask` function(system call)
  - blocked bit vectors也称为signal mask

### Sending Signals: Process Groups

每个进程都属于一个进程组。

![png](15-ECF-Signals/15-ecf-signals_15.JPG)

上图shell创建了一个前台子进程，并将该子进程的pgid修改为其pid（pgid=pid=20）。当这个子进程创建另外一个子进程时，继承了相同的pgid。

### Sending Signals with /bin/kill Program

进程组有一个好处是可以同时向组中的进程发送信号。

![png](15-ECF-Signals/15-ecf-signals_16.JPG)

kill第一个参数表示要发送什么信号

### Sending Signals from the Keyboard

另一种发送信号的方法是在命令行这里输入ctrl-c(SIGINT)或ctrl-z(SIGTSTP，直到收到SIGCONT)

![png](15-ECF-Signals/15-ecf-signals_17.JPG)

![png](15-ECF-Signals/15-ecf-signals_18.JPG)

### Sending Signals with kill Function

![png](15-ECF-Signals/15-ecf-signals_19.JPG)

### Receiving Signals

前提：Suppose kernel is returning from an exception handler and is ready to pass control to process p

- 内核通过一个公式计算`pnb = pending & ~blocked`

  - The set of pending nonblocked signals for process p

- `If (pnb == 0)`: Pass control to next instruction in the logical flow for p。代表没有待处理的信号。
- `else`
  - Choose least nonzero bit k(*最小非零位*) in pnb and force process p to receive signal k.
  - 收到信号后，p会触发一些操作(action)
  - Repeat for all nonzero k in pnb.遍历完所有的非零位。
  - Pass control to next instruction in logical flow for p.
  
#### Default Actions

Each signal type has a predefined default action, which is one of:

- The process terminates
- The process stops until restarted by a SIGCONT signal
- The process ignores the signal

### Installing Signal Handlers

可以通过使用`signal`函数系统调用来修改信号默认操作

`handler_t *signal(int signum, handler_t *handler)`

handler参数：

- **SIG_IGN**: ignore signals of type signum
- **SIG_DFL**: revert to the default action on receipt of signals of type signum
- **Otherwise**, handler is the address of a user-level signal handler
  - Called when process receives signal of type signum
  - 又可以称为"installing" the handler
  - 当处理程序执行它的return 语句时，控制权将返回到因接收信号而中断的进程的控制流中的指令并继续执行

![png](15-ECF-Signals/15-ecf-signals_24.JPG)

### Signals Handlers as Concurrent Flows

![png](15-ECF-Signals/15-ecf-signals_26.JPG)

### Nested Signal Handlers

![png](15-ECF-Signals/15-ecf-signals_27.JPG)

### Blocking and Unblocking Signals

隐式阻塞机制: handler不能因接收到相同类型的另一个信号而打断，可以被另外一种类型打断。

内核提供了一个系统调用Sigprocmask函数，允许显式阻塞和解除阻塞信号

阻塞和解除阻塞一组信号:

- Sigemptyset: Create empty set
- Sigfillset: Add every signal number to set
- Sigaddset: Add signal number to set
- Sigdelset: Delete signal number from set

![png](15-ECF-Signals/15-ecf-signals_29.JPG)

使用Sigemptyset创建一个空的mask（全为零的mask）。

使用Sigprocmask暂时停止接收mask集合中的信号，&mask被更新，之前的值被复制到了&prev_mask。

之后再次调用Sigprocmask恢复

