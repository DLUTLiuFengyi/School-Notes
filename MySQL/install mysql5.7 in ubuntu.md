### install mysql5.7 in ubuntu18.04

#### install

```shell
sudo apt-get install mysql-server-5.7
```

#### change root password

```shell
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# insert a line under "skip-external-locking"
skip-grant-tables

# restart mysql
/etc/init.d/mysql restart

mysql -uroot -p
```

```mysql
>show databases;
>show tables;
>use mysql
>select user,plugin from user;
>update user set authentication_string=password("123456"),plugin='mysql_native_password' where user='root';
>select user,plugin from user;
>quit
```

```shell
sudo vim /etc/mysql/mysql.conf.d/mysqld.cnf

# skip-grant-tables

# restart mysql
/etc/init.d/mysql restart
```

https://www.cnblogs.com/cpl9412290130/p/9583868.html

#### unbind

```shell
vim /etc/mysql/my.cnf
!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/

cd mysql.conf.d
sudo vim mysqld.cnf
# bind-address
```

#### access rights

https://blog.csdn.net/july_2/article/details/41896295

```mysql
>GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '123456' WITH GRANT OPTION; 
```

```shell
service mysql restart
service mysql status
```

