#!/bin/bash

# ==============================================================================
# Author          : Yuanjun.Li
# Email           : yourchanges@gmail.com
# Date            : 20170824
# Version         : 1.0.0
# Description     : This script is used to dump given JVM process' status
# ==============================================================================

SERVER_PORT=$1
DUMP_DIR=$2

if [ ! -n "$DUMP_DIR" ]; then
  echo "用法：$0 <SERVER_PORT> <DUMP_DIR>"
  echo "<DUMP_DIR> 会被自动创建，如果不存在该目录的话"
  exit 1
fi

if [ ! -d $DUMP_DIR ]; then
	mkdir -p $DUMP_DIR
fi

cd `dirname $0`

if [ -f ../env.sh ]; then
  source ../env.sh
fi

cd -

PIDS=`ps aux | grep java | grep "server.port=$SERVER_PORT" | awk '{print $2}'`

if [ -z "$PIDS" ]; then
    echo "错误: 指定端口的服务进程没有运行!"
    exit 1
fi

DUMP_DATE=`date +%Y%m%d%H%M%S`

echo -e "正在dump ...\c"
for PID in $PIDS ; do

    jstack $PID > $DUMP_DIR/jstack-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jinfo $PID > $DUMP_DIR/jinfo-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jstat -gcutil $PID > $DUMP_DIR/jstat-gcutil-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jstat -gccapacity $PID > $DUMP_DIR/jstat-gccapacity-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jmap $PID > $DUMP_DIR/jmap-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jmap -F -heap $PID > $DUMP_DIR/jmap-heap-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	jmap -F -histo $PID > $DUMP_DIR/jmap-histo-$PID-$DUMP_DATE.dump 2>&1
	echo -e ".\c"
	
	if [ -r /usr/sbin/lsof ]; then
	   /usr/sbin/lsof -p $PID > $DUMP_DIR/lsof-$PID-$DUMP_DATE.dump
	   echo -e ".\c"
	fi
done

echo
echo "Dump $PIDS 成功!"


