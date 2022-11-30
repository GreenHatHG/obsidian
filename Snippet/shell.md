# Top File

```shell
find . -type f -exec du -Sh {} + | sort -rh | head -n 20
```

# Spilt Txt

```shell
split --additional-suffix=.txt -a 1 -d -l 20000 aaa.txt aaa_
```