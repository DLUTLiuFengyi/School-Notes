```sh
yarn-per-job新老版本写法

<=1.10: flink run -m yarn-cluster -c xxxxx xx.jar

>=1.11: flink run -t yarn-per-job -c xxxxx xx.jar
```

