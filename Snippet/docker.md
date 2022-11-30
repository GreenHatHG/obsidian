# Centos Python

```dockerfile
ENV TZ=Asia/Shanghai

RUN set -ex \
    && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime \
    && yum update -y $(rpm -qa | sed -n 's+^\(glibc.*\)-2.28-.*+\1+p' ) --allowerasing \
    && yum update ca-certificates -y \
    && update-ca-trust \
    && yum install epel-release -y \
    && yum remove java-1.8.0-openjdk-headless -y \
    && yum install -y net-tools psmisc unzip lsof python36 python36-devel compat-openssl10 \
    && yum clean all && rm -rf /var/cache/yum/* /var/cache/dnf/* $(find / -name *.rpmnew) /tmp/* \
    && pip3 install setuptools-rust -i https://mirrors.cloud.tencent.com/pypi/simple/ --extra-index-url https://mirrors.cloud.tencent.com/pypi/simple/ \
    && pip3 install --upgrade pip

WORKDIR /app
ADD ./requirements.txt .
RUN pip3 install -r requirements.txt -i https://mirrors.cloud.tencent.com/pypi/simple/ --extra-index-url https://mirrors.cloud.tencent.com/pypi/simple/
ADD . .
RUN rm -rf .git __pycache__ && pip3 cache purge
```

# build

```shell
docker build . -t image_name

docker save -o image_name.tar image_name

docker load -i image_name.tar
```