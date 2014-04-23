hoya-docker-ubuntu
==================

test container to reproduce https://issues.apache.org/jira/browse/YARN-1842

##Build the image
docker build --no-cache=false -t  sequenceiq/hoya-ubuntu .

##Run the image
docker run -i -t sequenceiq/hoya-ubuntu /etc/bootstrap.sh -bash


