## Ubuntu Issues

### Change the mirror

cd ~

mkdir filebackup

cd filebackup

cp /etc/apt/sources.list .

sudo vim /etc/apt/sources.list

Delete all content in sources.list

Copy from this:

```shell
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-updates main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-backports main restricted universe multiverse
deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-security main restricted universe multiverse

# 预发布软件源，不建议启用
# deb https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://mirrors.tuna.tsinghua.edu.cn/ubuntu/ focal-proposed main restricted universe multiverse
```

sudo apt-get update



### apt-get problems

#### E: Sub-process /usr/bin/dpkg returned an error code (1)

* cd /var/lib/dpkg/
* sudo mv info/ info_bak
* sudo mkdir info
* sudo apt-get update
* sudo spt-get -f install  # Repair
* sudo mv info/* info_bak/
* sudo rm -rf info
* sudo mv info_bak info

