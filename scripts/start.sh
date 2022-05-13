#!/bin/bash

# ==============================================================================
# Author          : Yuanjun.Li
# Email           : yourchanges@gmail.com
# Date            : 20180624
# JavaVersion     : java8-11
# Version         : 1.0.1
# Description     : This script is used to start a springboot jar file with given port
# ==============================================================================

#set -x

cd `dirname $0`


JAR_PATH=$1
SERVER_PORT=$2

if [ "$JAR_PATH" == "" ]; then
  echo "用法：$0 <JAR_PATH> <SERVER_PORT> [PROFILE] [PG_MEM] [HEAP_MEM]"
  exit 1
fi

if [ "$SERVER_PORT" == "" ]; then
  echo "用法：$0 <JAR_PATH> <SERVER_PORT> [PROFILE] [PG_MEM] [HEAP_MEM]"
  exit 1
fi

if [ "$PROFILE" == "" ]; then
  PROFILE="prod"
fi

PROFILE=$3
PG_MEM=$4
HEAP_MEM=$5

if [ "$PROFILE" == "" ]; then
  PROFILE="prod"
fi

if [ "$PG_MEM" == "" ]; then
  PG_MEM="128"
fi

if [ "$HEAP_MEM" == "" ]; then
  HEAP_MEM="10240"
fi

cdir=`pwd`

JAVA_OPTS=" -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true  -Duser.timezone=Asia/Shanghai "



JAVA_MEM_OPTS=""
BITS=`java -version 2>&1 | grep -i 64-bit`


if [ -n "$BITS" ]; then
    JAVA_MEM_OPTS=" -server -Xmx${HEAP_MEM}m -XX:MetaspaceSize=${PG_MEM}m -Xss512k -XX:+DisableExplicitGC -XX:+CMSParallelRemarkEnabled -XX:+UseCMSInitiatingOccupancyOnly -XX:CMSInitiatingOccupancyFraction=70 "
else
    JAVA_MEM_OPTS=" -server -Xmx${HEAP_MEM}m -XX:MetaspaceSize=${PG_MEM}m -Xss512k -XX:SurvivorRatio=2 -XX:+UseParallelGC "
fi


echo -e "正在启动 ...\c"
nohup java $JAVA_OPTS $JAVA_MEM_OPTS -jar $JAR_PATH --spring.profiles.active=$PROFILE --server.port=$SERVER_PORT  > $JAR_PATH.$SERVER_PORT.log 2>&1 &


PIDS=`ps aux | grep java | grep "server.port=$SERVER_PORT" | awk '{print $2}'`

COUNT=0
NUM=0
while [ $COUNT -lt 1 ]; do    
    echo -e ".\c"
    sleep 1
    NUM=$(( $NUM + 1 ))

    #如果进程已经不在，则快速退出
    IPIDS=`ps aux | grep java | grep "server.port=$SERVER_PORT" | awk '{print $2}'`
    if [ -z "$IPIDS" ]; then
        echo "启动失败: 应用[ $JAR_PATH ]端口[ $SERVER_PORT ]对应的服务进程已经自动退出或者没有运行!"
        #退出码，39 不可改变，部署代理器基于该代码，进行一次重试
        exit 39
    fi

    #120秒超时强制退出
    if [ $NUM -gt 120 ]; then
        for PID in $PIDS ; do
           kill -9 $PID > /dev/null 2>&1
        done

        echo "启动失败: 启动超时，应用[ $JAR_PATH ]端口[ $SERVER_PORT ]对应的服务进程被强制退出!"
        #默认失败退出码，不进行重试
        exit 1
    fi
    
    #判断端口监听与否
    if [ -n "$SERVER_PORT" ]; then
        COUNT=`netstat -an | grep 0.0.0.0:$SERVER_PORT | wc -l`
    fi
    if [ $COUNT -gt 0 ]; then
        break
    fi
    
done

echo "启动成功!"
echo "进程ID: $PIDS"
exit 0


