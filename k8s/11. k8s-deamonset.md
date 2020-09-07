一直满足某个pod的副本数（在每个node上）为1。

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: daemonset-example
  labels: 
    app: daemoset
spec:
  selector: 
    matchLabels:
      # 匹配的标签名
      # 必须与上面的labels: app: 对应
      name: daemonset-example
  template: 
    metadata:
      labels:
        name: daemonset-example
    spec:
      containers:
      - name: daemonset-example
        image: wangyanglinux/myapp:v1
```

