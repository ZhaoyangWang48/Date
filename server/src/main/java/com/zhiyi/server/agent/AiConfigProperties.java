package com.zhiyi.server.agent;

import org.springframework.boot.context.properties.ConfigurationProperties;

@ConfigurationProperties("zhiyi.ai")
public record AiConfigProperties(String apiKey, String baseUrl, String embeddingModel, String chatModel) {
}
