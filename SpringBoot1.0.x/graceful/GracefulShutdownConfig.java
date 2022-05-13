package com.web.common.config.graceful;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.context.embedded.ConfigurableEmbeddedServletContainer;
import org.springframework.boot.context.embedded.EmbeddedServletContainerCustomizer;
import org.springframework.boot.context.embedded.tomcat.TomcatEmbeddedServletContainerFactory;
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

    /** 只支持Embedded嵌入式 服务容器 **/
    @Bean
    public EmbeddedServletContainerCustomizer tomcatCustomizer() {
        return new EmbeddedServletContainerCustomizer() {

            @Override
            public void customize(ConfigurableEmbeddedServletContainer configurableEmbeddedServletContainer) {
                if (configurableEmbeddedServletContainer instanceof TomcatEmbeddedServletContainerFactory) {
                    ((TomcatEmbeddedServletContainerFactory) configurableEmbeddedServletContainer)
                            .addConnectorCustomizers(gracefulShutdown());
                }
            }

        };
    }
}
