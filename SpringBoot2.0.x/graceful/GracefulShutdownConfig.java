package com.web.common.config.graceful;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.web.embedded.tomcat.TomcatServletWebServerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

/**
 * Tomcat优雅停机配置
 */
@Configuration
public class GracefulShutdownConfig {

    @Value("${graceful.shutdown.timeout.seconds:30}")
    private long shutdownTimeoutSeconds;

    @Bean
    public GracefulShutdownTomcat gracefulShutdown() {
        return new GracefulShutdownTomcat(shutdownTimeoutSeconds, TimeUnit.SECONDS);
    }


    @Bean
    public TomcatServletWebServerFactory tomcatServletContainer(GracefulShutdownTomcat gracefulShutdownTomcat) {
        TomcatServletWebServerFactory factory = new TomcatServletWebServerFactory();
        factory.addConnectorCustomizers(gracefulShutdownTomcat);
        return factory;
    }


}
