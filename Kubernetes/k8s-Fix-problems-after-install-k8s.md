### Fix some problems after install k8s

#### Fix cs

sudo kubectl get cs

Find that the status of controller-manager and scheduler is unhealthy

sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml

sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml

#- --port=0

Restart 

sudo systemctl restart kubelet



#### Fix CrashLoopBackOff

sudo kubectl describe pod kube-flannel-ds-cw4gh -n kube-system

sudo kubectl logs kube-flannel-ds-cw4gh -n kube-system

Check the cidr in master01

sudo kubectl describe node master01 | grep cidr

Find that is null

