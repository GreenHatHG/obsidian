# 修改已经提交的git的名字邮箱

```shell
pip3 install git-filter-repo
git filter-repo --commit-callback '
    if commit.author_email == b"incorrect@email":
        commit.author_email = b"correct@email" 
        commit.author_name = b"Correct Name"
        commit.committer_email = b"correct@email" 
        commit.committer_name = b"Correct Name"
'
# 需要重新设置remote并强制提交
git remote add origin url
git push -u origin master -f
```
https://stackoverflow.com/questions/4981126/how-to-amend-several-commits-in-git-to-change-author/69947947#69947947