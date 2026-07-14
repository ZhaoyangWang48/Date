package com.zhiyi.server.agent;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("zhiyi.kimi")
public record KimiConfigProperties(String apiKey, String baseUrl, String model) {
}
