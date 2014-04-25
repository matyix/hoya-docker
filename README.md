hoya-docker
==================

Test container to reproduce https://issues.apache.org/jira/browse/YARN-1842

#####Versions
Hadoop 2.3, Hoya 0.13, HBase 0.98, Zookeeper 3.3.6

#####Linux OS
Ubuntu, Debian

Choose the appropriate Linux OS, and switch/clone the branch. Once in the branch:

##Build the image
docker build --no-cache=false -t  sequenceiq/hoya-XXXXX .
_XXXXX=ubuntu or debian_

##Run the image
docker run -i -t sequenceiq/hoya-XXXXX /etc/bootstrap.sh -bash

Reproduce [YARN-1842](https://issues.apache.org/jira/browse/YARN-1842)


##### Creating a HBase cluster using Hoya

``` bash

  hoya create hbase --role master 1 --role worker 1
    --manager localhost:8032
    --filesystem hdfs://localhost:9000 --image hdfs://localhost:9000/hbase.tar.gz
    --appconf file:///usr/local/hbaseconf/
    --zkhosts localhost
```
##### Freeze the cluster should throw the exceptions

``` bash
  hoya freeze hbase --manager localhost:8032 --filesystem hdfs://localhost:9000
```

##### Get the logs
cd /usr/local/hadoop/logs/
grep -rli "Exception" *
