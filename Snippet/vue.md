# vue{{}}添加空格

```javascript
{{"开始时间："+ reqInfo.StartTime+ '\xa0\xa0\xa0\xa0'+ "耗时："+reqInfo.Duration}}
```

# 字符串数组排序

```javascript
array.sort((a, b) => a.length - b.length || a.localeCompare(b))
```

# 字符串不转义

```javascript
console.log(JSON.parse(String.raw`[{"StartTime":"2021-03-09 18:57:33.894","EndTime":"2021-03-09 18:57:34.410"}]`))
```

