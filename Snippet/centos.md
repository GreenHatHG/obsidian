# Install Python3.7

```shell
#!/bin/env bash

## 下载 Python 源码，如果已下载源码在脚本当前目录下，可注释跳过下载步骤
wget https://www.python.org/ftp/python/3.7.12/Python-3.7.12.tgz

## 安装编译依赖组件
yum -y install wget zlib-devel bzip2-devel openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make libffi-devel xz-devel

## 解压安装
# 解压到/usr/local/src目录
tar zvxf Python-3.7.12.tgz -C /usr/local/src
cd /usr/local/src/Python-3.7.12
# 编译前配置
./configure prefix=/usr/local/python3 --enable-shared
# 编译构建
make -j8
# 安装Python
make install
# 清理编译产出的中间文件
make clean
# 链接构建产出的Python可执行文件到/usr/local/bin目录
ln -s /usr/local/python3/bin/python3 /usr/local/bin/python
# 链接构建产出的pip3可执行文件到/usr/local/bin目录
ln -s /usr/local/python3/bin/pip3 /usr/local/bin/pip
# 链接构建产出的Python动态库
ln -s /usr/local/python3/lib/libpython3.7m.so.1.0 /usr/lib/libpython3.7m.so.1.0
# 配置动态库
ldconfig

## 检查Python版本是否安装成功
echo -e "\033[1;42;37m[$(date "+%Y/%m/%d %H:%M:%S")] [Check]: 检查Python版本\033[0m"
python --version
echo -e "\033[1;42;37m[$(date "+%Y/%m/%d %H:%M:%S")] [Check]: 检查Python版本\033[0m"

## pypi下载源配置
mkdir ~/.pip/
echo "extra-index-url = https://mirrors.cloud.tencent.com/pypi/simple" >> ~/.pip/pip.conf
```

https://tencent.github.io/CodeAnalysis/en/advanced/install_python37_on_centos.html#%E4%B8%80%E9%94%AE%E5%AE%89%E8%A3%85%E8%84%9A%E6%9C%AC

# Run Python

```shell
docker run --network host --rm -v host_folder:image_folder image_name /bin/bash -c "export PYTHONPATH=. && python3 test.py"
```
