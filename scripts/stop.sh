#!/bin/bash

# ==============================================================================
# Author          : Yuanjun.Li
# Email           : yourchanges@gmail.com
# Date            : 20170824
# Version         : 1.0.0
# Description     : This script is used to stop given springboot JVM process by its port
# ==============================================================================

cd `dirname $0`

SERVER_PORT=$1

if [ ! -n "$SERVER_PORT" ]; then
  echo "用法：$0 <SERVER_PORT>"
  exit 1
fi

PIDS=`ps aux | grep java | grep "server.port=$SERVER_PORT" | awk '{print $2}'`

if [ -z "$PIDS" ]; then
    echo "错误: 指定端口的服务进程没有运行!"
    exit 1
fi

echo -e "正在停止 ...\c"
for PID in $PIDS ; do
    kill $PID > /dev/null 2>&1
done

COUNT=0
NUM=0
#等待程序处理积压的消息
while [ $COUNT -lt 1 ]; do    
    echo -e ".\c"
    sleep 1
    NUM=$(( $NUM + 1 ))

    COUNT=1
    for PID in $PIDS ; do
        PID_EXIST=`ps -f -p $PID | grep java`
        if [ -n "$PID_EXIST" ]; then
            COUNT=0
            break
        fi
    done

#90秒超时强制退出
    if [ $NUM -gt 90 ]; then
        for PID in $PIDS ; do
           kill -9 $PID > /dev/null 2>&1
        done
        break
    fi
done

echo "成功关闭进程: $PIDS"


