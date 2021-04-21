```mysql
>create database clicdb character set utf8;
>use clicdb
>create table student( id int(6), name varchar(50));
>load data local infile '~/data/student.csv' into table student character set utf8 fields terminated by ',' optionally enclosed by '"' escaped by '"' lines terminated by '\r\n';
```

```sql
select distinct student.id as stuNum,name as stuName,grade as stuGrade from student,course,grade where student.id=course.id and student.id=grade.id and cid in (select cid from course,student where course.id=student.id and student.id in (select id from student where student.name='xiaoming'))
```



