### 强制停机

无论是Linux的`Kill -9 pid`还是windows的`taskkill /f /pid`强制关闭进程，都会带来一些副作用，如：

1. 请求丢失：内存队列中等待执行的请求丢失；

2. 数据丢失：处于内存中的数据尚未持久化到磁盘中；

3. 业务中断：处理一半的业务被强行中断，却没有更新到数据库中；

4. 文件损坏：正在进行文件的write操作中，突然退出，导致文件损坏；

5. 锁表：在操作数据库多表更新时，事务方法执行中断，导致数据库锁表；

   

### 优雅停机
Java是通过 JDK 的 **ShutdownHook** 来完成优雅停机的，当程序接收到退出指令后，会标记为退出状态，此时不再接收新的消息，然后将积压的消息处理完后回收资源，最后关闭线程。所以不能直接使用`kill -9 PID` 等强制关闭指令，只有通过 **kill -2 PID**`（Ctrl + C）`或 **kill PID** `（kill -15 PID）`时，才会通知程序调用`ShutdownHook`方法。通常优雅停机需要有等待超时机制，如果在规定时间内还未完成退出前的操作，则由直接调用`kill -9 PID`，强制退出。



##### ShutdownHook用法

```java
Runtime.getRuntime().addShutdownHook(new Thread(() -> {
    System.out.println("关闭应用，释放资源");
}));
```



##### 优雅停机脚本stop.sh

```sh
#!/bin/bash

cd `dirname $0`

SERVER_PORT=$1

if [ ! -n "$SERVER_PORT" ]; then
  echo "用法：$0 <SERVER_PORT>"
  exit 1
fi

PIDS=`ps aux | grep java | grep "--server.port=$SERVER_PORT" | awk '{print $2}'`

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
```



### StringBoot配置

spring boot 2.3.x 版本以后，内置了优雅停机的机制，也就不需要自行扩展容器的线程池来处理， 目前spring boot嵌入式支持的web服务器（Jetty、Reactor Netty、Tomcat 和 Undertow）以及反应式和基于Servlet的web 应用程序都支持优雅停机功能。只需在`application.yml`中添加如下配置即可。

```yml
server:
  shutdown: graceful  #关停方式，默认IMMEDIATE(立即关闭)

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s #最大等待线程结束时间，默认30s
```

- spring boot 2.3.x之前的版本需要自己去扩展， 具体代码和脚本可以参考：[spring-boot-graceful-shutdown](https://github.com/jayknoxqu/spring-boot-graceful-shutdown)



### 容器表现行为

| Web 容器       | 表现行为                                 |
| -------------- | ---------------------------------------- |
| Tomcat 9.0.33+ | 停止接收请求，客户端新请求等待超时。     |
| Reactor Netty  | 停止接收请求，客户端新请求等待超时。     |
| Undertow       | 停止接收请求，客户端新请求直接返回 503。 |

