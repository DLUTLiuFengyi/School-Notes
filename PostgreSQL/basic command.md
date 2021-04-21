```postgresql
 create database clicdb encoding='UTF8';
 \l
 \c clicdb
 \d
 \d student
```

```shell
sudo su
su - username
```

```shell
liu@vmdb:~/data$ sudo cp -r student.csv /var/lib/postgresql/data
liu@vmdb:~/data$ sudo cp -r grade.csv /var/lib/postgresql/data
liu@vmdb:~/data$ sudo cp -r course.csv /var/lib/postgresql/data
```

```postgresql
clicdb=# \copy student from '~/data/student.csv' with csv header;
COPY 25
clicdb=# \copy grade from '~/data/grade.csv' with csv header;
COPY 27
clicdb=# \copy course from '~/data/course.csv' with csv header;
COPY 26
```

```postgresql
\q  #quit
```

```postgresql
sudo -i -u postgres
psql
\du #watch all users
create user xiaohua superuser password '123456';
grant all privileges on database clicdb to xiaohua;
```

#### change linux user info

```shell
# delete the password of linux user postgres
sudo passwd -d postgres
# change password
sudo -u postgres passwd

# create
sudo adduser xiaohua

su - xiaohua
# log psql as xiaohua and access database clicdb
psql -d clicdb
```

#### open remote access

https://blog.csdn.net/baidu_41743195/article/details/104346602

```shell
sudo vim /etc/postgresql/10/main/pg_hba.conf
...
service postgresql restart
```

