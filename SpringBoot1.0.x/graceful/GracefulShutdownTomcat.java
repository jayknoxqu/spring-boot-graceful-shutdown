package com.web.common.config.graceful;

import org.apache.catalina.connector.Connector;
import org.apache.tomcat.util.threads.ThreadPoolExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.context.embedded.tomcat.TomcatConnectorCustomizer;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextClosedEvent;

import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

/**
 * 自定义Tomcat容器配置
 */
public class GracefulShutdownTomcat implements TomcatConnectorCustomizer, ApplicationListener<ContextClosedEvent> {

    private final static Logger LOG = LoggerFactory.getLogger(GracefulShutdownTomcat.class);

    private final long shutdownTimeout;

    private final TimeUnit unit;

    private volatile Connector connector;

    public GracefulShutdownTomcat(long shutdownTimeout, TimeUnit unit) {
        this.shutdownTimeout = shutdownTimeout;
        this.unit = unit;
    }

    @Override
    public void customize(Connector connector) {
        this.connector = connector;
    }

    @Override
    public void onApplicationEvent(ContextClosedEvent contextClosedEvent) {
        if (this.connector == null) {
            LOG.error("connector 为null, 这种通常是配置错误");
            return;
        }

        awaitTermination();
    }

    /**
     * 这个函数不要用LOG打印日志，因为在执行的时候，context可能已经关闭了导致日志输出不了，而是采用标准错误流进行记录； <br/>
     * 同时，这个函数也不会进入debug模式，因为debug端口在这个时候已经被关闭了；
     */
    public void awaitTermination() {
        connector.pause();
        Executor executor = connector.getProtocolHandler().getExecutor();
        if (executor instanceof ThreadPoolExecutor) {
            System.err.println("开始对tomcat进行优雅停机");
            try {
                ((ThreadPoolExecutor) executor).shutdown();
                if (!((ThreadPoolExecutor) executor).awaitTermination(shutdownTimeout, unit)) {
                    System.err.println("Tomcat没有在指定的时间里优雅停机, 可能有用户的业务受影响；超时时间(秒)：" + this.shutdownTimeout);
                }
                System.err.println("优雅停机完成");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

        }
    }
}
