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

