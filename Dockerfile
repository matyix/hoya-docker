# Creates pseudo distributed hadoop 2.3 on Ubuntu
#
# docker build -t sequenceiq/hadoop-ubuntu .

FROM debian
MAINTAINER SequenceIQ

USER root

# install dev tools
RUN apt-get update
RUN apt-get install -y wget curl tar sudo openssh-server openssh-client rsync

# passwordless ssh
RUN rm -rf /etc/ssh/ssh_host_dsa_key
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
RUN rm -rf /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN rm -rf /root/.ssh/id_rsa
RUN ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa
RUN cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# install Java 7
RUN apt-get install -y openjdk-7-jdk

# set a bunch of environment variables
ENV JAVA_HOME /usr/lib/jvm/java-7-openjdk-amd64
ENV PATH $JAVA_HOME/bin:$PATH

# hadoop
RUN curl -s http://www.eu.apache.org/dist/hadoop/common/hadoop-2.3.0/hadoop-2.3.0.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s hadoop-2.3.0 hadoop


ENV HADOOP_PREFIX /usr/local/hadoop
RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input
RUN cp $HADOOP_PREFIX/etc/hadoop/*.xml $HADOOP_PREFIX/input

# pseudo distributed
ADD core-site.xml $HADOOP_PREFIX/etc/hadoop/core-site.xml
ADD hdfs-site.xml $HADOOP_PREFIX/etc/hadoop/hdfs-site.xml

ADD mapred-site.xml $HADOOP_PREFIX/etc/hadoop/mapred-site.xml
ADD yarn-site.xml $HADOOP_PREFIX/etc/hadoop/yarn-site.xml

# fixing the libhadoop.so like a boss
RUN rm  /usr/local/hadoop/lib/native/*
RUN curl -Ls http://dl.bintray.com/sequenceiq/sequenceiq-bin/hadoop-native-64.tar|tar -x -C /usr/local/hadoop/lib/native/

#format namenode
RUN $HADOOP_PREFIX/bin/hdfs namenode -format

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config
RUN chown root:root /root/.ssh/config

# # insatlling supervisord
# RUN apt-get install -y python-setuptools
# RUN easy_install pip
# RUN curl https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -o - | python
# RUN pip install supervisor
#
# ADD supervisord.conf /etc/supervisord.conf

ADD bootstrap.sh /etc/bootstrap.sh
RUN chown root:root /etc/bootstrap.sh
RUN chmod 700 /etc/bootstrap.sh

ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh
RUN chmod +x /usr/local/hadoop/etc/hadoop/*-env.sh
RUN ls -la /usr/local/hadoop/etc/hadoop/*-env.sh

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config
RUN echo "UsePAM no" >> /etc/ssh/sshd_config

RUN service ssh start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root
RUN service ssh start && $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_PREFIX/etc/hadoop/ input

# hoya
RUN curl -s http://dffeaef8882d088c28ff-185c1feb8a981dddd593a05bb55b67aa.r18.cf1.rackcdn.com/hoya-0.13.1-all.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s hoya-0.13.1 hoya
ENV HOYA_HOME /usr/local/hoya
ENV PATH $PATH:$HOYA_HOME/bin

# hbase
RUN curl -so /usr/local/hbase-0.98.0.tar.gz http://www.eu.apache.org/dist/hbase/hbase-0.98.0/hbase-0.98.0-hadoop2-bin.tar.gz
RUN $BOOTSTRAP && $HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave && $HADOOP_PREFIX/bin/hdfs dfs -put /usr/local/hbase-0.98.0.tar.gz /hbase.tar.gz
RUN mkdir /usr/local/hbaseconf
ADD hadoop-metrics.properties /usr/local/hbaseconf/hadoop-metrics.properties
ADD hbase-env.sh /usr/local/hbaseconf/hbase-env.sh
ADD hbase-policy.xml /usr/local/hbaseconf/hbase-policy.xml
ADD hbase-site.xml /usr/local/hbaseconf/hbase-site.xml
ADD log4j.properties /usr/local/hbaseconf/log4j.properties

# zookeeper
RUN curl -s http://xenia.sote.hu/ftp/mirrors/www.apache.org/zookeeper/zookeeper-3.4.6/zookeeper-3.4.6.tar.gz | tar -xz -C /usr/local/
RUN cd /usr/local && ln -s zookeeper-3.4.6 zookeeper
ENV ZOO_HOME /usr/local/zookeeper
ENV PATH $PATH:$ZOO_HOME/bin
RUN mv $ZOO_HOME/conf/zoo_sample.cfg $ZOO_HOME/conf/zoo.cfg
RUN mkdir /tmp/zookeeper


CMD ["/etc/bootstrap.sh", "-d"]

EXPOSE 50020 50090 50070 50010 50075 8031 8032 8033 8040 8042 49707 22 8088 8030
