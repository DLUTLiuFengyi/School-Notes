### 提交本地分支的更新
查看更新情况

`git status`   

将项目更新添加到本地缓冲区

`git add .`   

将本地缓冲区内容提交到本地分支(仓库)

`git commit -m "更新描述信息"`   

将本地分支内容提交到远程分支(若此时无远程分支，则自动创建远程分支)

`git push origin 本地分支名:远程分支名`   



### 获取远程分支的更新

#### 方法1
##### [在要接受更新的本地分支下]
(如要撤销合并前本地的更新：`git restore 修改的文件名` + 手动删除新添加的文件名)
`git fetch origin 远程分支名`
(如要查看差别：`git log -p 本地分支名..origin/远程分支名`)
`git merge origin/远程分支名`
#### 方法2
##### [在要接受更新的本地分支下]
`git pull origin 远程分支名`



### 删除本地或远程分支

`git checkout master`
`git branch -d 本地分支名`
`git push origin -d 远程分支名`
把-d改成-D是强制删除



### 版本回滚

`git revert commit的id`
`git push -f origin 本地分支名:远程分支名`



### 查看本地或远程分支
`git branch`   查看本地分支
`git branch -r`   查看远程分支
`git branch -a`   查看本地和远程分支



### 用远程分支创建本地分支
#### 方法1

给本地仓库更新远程仓库的内容

`git fetch`  

根据远程内容和本地分支名新建本地分支并自动切换到该分支下 

`git checkout -b 本地分支名 origin/远程分支名`   

#### 方法2

根据远程内容和本地分支名新建本地分支

`git fetch origin 本地分支名:远程分支名`  



### 本地分支合并到远程分支

基于远程某一个分支自己在本地进行开发，开发之后需要把自己的工作push到远程分支。假设`develop`是远程分支名，`my-branch`是将要合并到`develop`的本地分支。

* #### 本地先链接到中央仓库的develop分支

  `git checkout -b develop origin/develop`

* #### 本地分支基于develop分支

  `git branch my-branch develop`

* #### 合并前，先确保develop分支是最新的

  `git pull origin develop`

* #### 切换到拉到本地的远程分支

  `git checkout develop`

* #### 合并

  `git merge my-branch`

* #### 推到中央仓库

  `git push`

