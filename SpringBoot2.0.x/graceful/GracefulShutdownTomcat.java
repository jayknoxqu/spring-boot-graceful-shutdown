package com.web.common.config.graceful;

import org.apache.catalina.connector.Connector;
import org.apache.tomcat.util.threads.ThreadPoolExecutor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.web.embedded.tomcat.TomcatConnectorCustomizer;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextClosedEvent;

import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

/**
 * 自定义Tomcat容器配置
 * 
 * @see "https://github.com/spring-projects/spring-boot/issues/4657"
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
            LOG.error("Connector for null, This is usually a configuration error");
            return;
        }
        awaitTermination();
    }

    /**
     * 这个函数不要用LOG打印日志，因为在执行的时候，context可能已经关闭了导致日志输出不了，而是采用标准错误流进行记录； <br/>
     * 同时，这个函数也不会进入debug模式，因为debug端口在这个时候已经被关闭了；
     */
    private void awaitTermination() {
        this.connector.pause();
        Executor executor = connector.getProtocolHandler().getExecutor();
        if (executor instanceof ThreadPoolExecutor) {
            System.err.println("-- Start tomcat graceful shutdown --");
            try {
                ((ThreadPoolExecutor) executor).shutdown();
                if (!((ThreadPoolExecutor) executor).awaitTermination(shutdownTimeout, unit)) {
                    System.err.println("Tomcat thread pool did not shut down gracefully within " + this.shutdownTimeout + " seconds. Proceeding with forceful shutdown");
                }
                System.err.println("--  End tomcat graceful shutdown  --");
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }

        }
    }

}
