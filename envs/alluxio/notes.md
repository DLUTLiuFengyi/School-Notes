### 官方文档

#### 为什么在linux上运行Alluxio需要sudo权限？

默认情况下，Alluxio使用[RAMFS](https://www.kernel.org/doc/Documentation/filesystems/ramfs-rootfs-initramfs.txt) 存储内存数据。用户在MacOS系统下可以挂载ramfs，不需要超级用户身份。然而，在linux系统下，用户运行”mount”命令（以及 “umount”, “mkdir” 和 “chmod” 命令）需要sudo权限。

#### 用户没有sudo权限，仍然可以在linux下使用Alluxio么？

假设用户没有sudo权限，那么必须有一个RAMFS（例如`/path/to/ramdisk`）已经被系统管理员挂载，并且用户对此RAMFS有读写权限。你可以在`conf/alluxio-site.properties`文件中指定该路径：

```
alluxio.worker.tieredstore.level0.alias=MEM
alluxio.worker.tieredstore.level0.dirs.path=/path/to/ramdisk
```

然后在不需要请求root权限的情况下启动Alluxio，使用上述的目录作为存储器：

```
$ ./bin/alluxio-start.sh local NoMount
```

### 博客1

https://www.jianshu.com/p/f417806156cf

如果是root用户起的，使用Mount，如果是非root用户起的，用SudoMount。第一次需要这样，之后启动直接./bin/alluxio-start.sh all就可以

解决方法是到两台worker节点手动执行：
 `/bin/alluxio-start.sh -a worker SudoMount`
 然后回到master节点
 `./bin/alluxio-stop.sh all`
 `./bin/alluxio-start.sh all`

就可以全部正常启动了

```undefined
./bin/alluxio-stop.sh all
./bin/alluxio format
./bin/alluxio-start.sh all SudoMount
```