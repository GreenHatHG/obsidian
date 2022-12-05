# Retry

```python
import time

from functools import partial, wraps


def reapt(func=None, *, limit=3, interval=5):
    if func is None:
        return partial(reapt, limit=limit, interval=interval)

    @wraps(func)
    def wrapper(self: 'A', *args, **kw):
        return self.reapt(func, *((self,) + args), limit=limit, interval=interval, **kw)

    return wrapper


class A:
    def __init__(self):
        self.name = '123'
        self.update_count = 1

    @reapt
    def test(self, name):
        self.name = name
        print(self.name)

    def chang(self):
        self.update_count += 1

    def reapt(self, func, *args, limit=1, interval=2, **kwargs):
        for i in range(limit):
            self.chang()
            func(*args, **kwargs)
            time.sleep(interval)


if __name__ == '__main__':
    A().test('abc')
```
[https://pybit.es/articles/decorator-optional-argument/](https://pybit.es/articles/decorator-optional-argument/)

[https://stackoverflow.com/questions/32613439/pass-self-to-decorator-object](https://stackoverflow.com/questions/32613439/pass-self-to-decorator-object)

[https://stackoverflow.com/questions/59720022/typeerror-got-multiple-values-for-argument-when-passing-in-args](https://stackoverflow.com/questions/59720022/typeerror-got-multiple-values-for-argument-when-passing-in-args)

[https://stackoverflow.com/questions/15301999/default-arguments-with-args-and-kwargs](https://stackoverflow.com/questions/15301999/default-arguments-with-args-and-kwargs)

[https://stackoverflow.com/questions/10176226/how-do-i-pass-extra-arguments-to-a-python-decorator](https://stackoverflow.com/questions/10176226/how-do-i-pass-extra-arguments-to-a-python-decorator)

# Dict To Json

```python
import ast


for (id, failed_info_new, error_info_new) in cursor:
    if error_info_new != "":
        try:
            json.loads(error_info_new)
        except:
            dict = ast.literal_eval(error_info_new)
            update_list[id] = json.dumps(dict, ensure_ascii=False)
```

# Run Shell

```python
import subprocess

def run_shell_command(command_line, timeout=None):
    """执行shell命令，阻塞运行"""
    logger.info('Subprocess: "' + command_line + '"')

    try:
        command_line_process = subprocess.Popen(
            command_line,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            shell=True
        )

        # process_output is now a string, not a file
        process_output, _ = command_line_process.communicate(timeout=timeout)
        res = command_line_process.wait(timeout=timeout)
        process_output = process_output.decode("utf-8")
        logger.info(f"process_output: {process_output}")
    except (OSError, subprocess.CalledProcessError) as exception:
        logger.info('Exception occured: ' + str(exception))
        logger.info('Subprocess failed')
        return False
    else:
        # no exception was raised
        logger.info('Subprocess finished')

    return process_output
```

# Hook Obj All Function

```python
def _hook_methods(self):
    methods = [method_name for method_name in dir(self.obj)
                            if callable(getattr(self.obj, method_name)) and not method_name.startswith('_')]

    def start_step_function_desc(f, *args, **kwargs):
        lines = str(f.__doc__).splitlines()
        desc = ''
        for line in lines:
            if line:
                desc = line.strip()
                break
        desc = f"obj-{desc}"
        self.start_step(desc)
        self.logger.info(f"{desc} args: {args}")
        self.logger.info(f"{desc} kwargs: {kwargs}")

    def prefix_function(function, pre_function):
        @functools.wraps(function)
        def run(*args, **kwargs):
            pre_function(function, *args, **kwargs)
            return function(*args, **kwargs)
        return run

    skip_list = ['ping']
    for method in methods:
        if method in skip_list:
            continue
        setattr(self.obj, method, prefix_function(getattr(self.obj, method),
                                                            start_step_function_desc))
```

# Find Files Recursively

Python 3.5

```python
from pathlib import Path

for path in Path('src').rglob('*.c'):
    print(path.name)
```