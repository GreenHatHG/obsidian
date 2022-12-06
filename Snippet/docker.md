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
docker build --build-arg http_proxy=http://192.168.3.68:8118 --build-arg https_proxy=http://192.168.3.68:8118 . -t image_name

docker save -o image_name.tar image_name

docker load -i image_name.tar
```

# Caddy Go SSH

```dockerfile
FROM golang:1.15.7-buster

# timezone
RUN apt update && apt install -y tzdata; \
    apt clean;

# sshd
RUN mkdir /var/run/sshd; \
    apt install -y openssh-server; \
    sed -i 's/^#\(PermitRootLogin\) .*/\1 yes/' /etc/ssh/sshd_config; \
    sed -i 's/^\(UsePAM yes\)/# \1/' /etc/ssh/sshd_config; \
    apt clean;

# entrypoint
RUN { \
    echo '#!/bin/bash -eu'; \
    echo 'ln -fs /usr/share/zoneinfo/${TZ} /etc/localtime'; \
    echo 'echo "root:${ROOT_PASSWORD}" | chpasswd'; \
    echo 'exec "$@"'; \
    } > /usr/local/bin/entry_point.sh; \
    chmod +x /usr/local/bin/entry_point.sh;

RUN apt install -y wget; apt clean
RUN wget https://github.com/caddyserver/caddy/releases/download/v2.3.0/caddy_2.3.0_linux_amd64.deb
RUN dpkg -i caddy_2.3.0_linux_amd64.deb
RUN rm caddy_2.3.0_linux_amd64.deb
RUN echo '{\n\
auto_https off\n\
}\n\
:5920\n\
reverse_proxy http://192.168.0.13:5920\n\
' > /usr/local/bin/Caddyfile

ENV TZ Asia/Shanghai

ENV ROOT_PASSWORD root

EXPOSE 22

ENTRYPOINT ["entry_point.sh"]
CMD ["sh", "-c", "caddy start --config /usr/local/bin/Caddyfile && /usr/sbin/sshd -De"]
```
