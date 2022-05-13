#!/bin/bash

cdir=`dirname $0`

cd $cdir

git pull origin master

./gradlew bootJar

r1=0

/home/devops/bin/stop.sh 8080
/home/devops/bin/stop.sh 9080
/home/devops/bin/start_xxl.sh /home/devops/spring-demo/build/libs/spring-demo-0.0.1.jar 8080 prod 9080

r1=$?
cd -

if [ ! $r1 -eq 0 ]; then
 echo "8080 start failed"
 exit $r1
fi

exit 0
