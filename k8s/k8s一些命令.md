### 进入容器

-it 交互，-- 固定格式，后接运行命令

`kubectl exec [pod名字] -c [容器名字] -it -- /bin/sh`

`kubectl exec [pod名字] -c [容器名字] -it -- rm -rf /usr/xxx/xxx.html`



新建一个index1.html并填入内容

echo "123" >> index1.html



### 删除pod

`kubectl delete pod [pod名字]`

`kubectl delete pod --all`



### 删除svc

`kubectl delete svc [svc1名字] [svc2名字] ...`



### 根据yaml创建pod

`kubectl create -f ini-pod.xml`



### 根据yaml修改pod

`kubectl apply -f ini-pod.xml`