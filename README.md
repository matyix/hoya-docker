hoya-docker-ubuntu
==================

Test container to reproduce https://issues.apache.org/jira/browse/YARN-1842

#####Versions
Hadoop 2.3, Hoya 0.13, HBase 0.98, Zookeeper 3.3.6

##Build the image
docker build --no-cache=false -t  sequenceiq/hoya-ubuntu .

##Run the image
docker run -i -t sequenceiq/hoya-ubuntu /etc/bootstrap.sh -bash

Reproduce [YARN-1842](https://issues.apache.org/jira/browse/YARN-1842)




##### Creating a HBase cluster using Hoya 

``` bash

  hoya create hbase --role master 1 --role worker 1
    --manager localhost:8032
    --filesystem hdfs://localhost:9000 --image hdfs://localhost:9000/hbase.tar.gz
    --appconf file:///usr/local/hbaseconf/
    --zkhosts localhost
```


