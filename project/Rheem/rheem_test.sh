#!/bin/bash

if [ $# -lt 1 ]
then
    echo "no thing happen"
    exit 0
fi

if [[ $1 = "exec" ]]
then 
    data_scale=$2
    jar_exec_type=$3

    echo "Generating wordcount_${data_scale}g.txt in /nfs/data/datasets/"
    sudo python generate_wordcount_data.py ${data_scale} nfs

    if [[ ${jar_exec_type} = "java" ]]
    then
        echo "exec type: java -jar "
        kubectl create -f ~/codes/yaml/job-rheem-wordcount-java-${data_scale}g.yml -n argo
    elif [[ ${jar_exec_type} = "spark" ]]
    then 
        echo "exec type: spark-submit"
	kubectl create -f ~/codes/yaml/job-rheem-wordcount-spark-${data_scale}g.yml -n argo
    else
        echo "There is no this type now"
    fi
    exit 0

elif [[ $1 = "wp" ]]
then 
    kubectl get pod -n argo -o wide
    exit 0

elif [[ $1 = "log" ]]
then
    pod_name=$2
    kubectl logs ${pod_name} -n argo
    exit 0

elif [[ $1 = "rmd" ]]
then
    data_scale=$2
    sudo rm /nfs/data/datasets/wordcount_${data_scale}g.txt
    exit 0

elif [[ $1 = "rmj" ]]
then
    data_scale=$2
    jar_exec_type=$3
    kubectl delete job rheem-wordcount-${jar_exec_type}-${data_scale}g
    exit 0
else
    echo "unknown args"
    exit 0
fi
