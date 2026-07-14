package com.zhiyi.server.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.server.agent.AiConfigProperties;
import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.domain.MemoryEntity;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;

import java.util.List;
import java.util.Map;

@Service
public class RecallSummaryAgent {
  private static final Logger log = LoggerFactory.getLogger(RecallSummaryAgent.class);
  private final AiConfigProperties aiConfig;
  private final ObjectMapper objectMapper;
  private RestClient client;

  public RecallSummaryAgent(AiConfigProperties aiConfig, ObjectMapper objectMapper) {
    this.aiConfig = aiConfig;
    this.objectMapper = objectMapper;
  }

  public record SummaryResult(String title, String summary, List<String> moodTags) { }

  public SummaryResult summarize(List<MemoryEntity> memories) {
    if (aiConfig.apiKey() == null || aiConfig.apiKey().isBlank()) {
      throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "AI 服务未配置");
    }

    String userPrompt = buildPrompt(memories);
    String rawJson = chatComplete(userPrompt);
    return parseResponse(rawJson);
  }

  private String buildPrompt(List<MemoryEntity> memories) {
    StringBuilder sb = new StringBuilder();
    sb.append("记忆内容：\n");
    for (int i = 0; i < memories.size(); i++) {
      MemoryEntity m = memories.get(i);
      sb.append(String.format("%d. [%s] 心情: %s | %s\n",
          i + 1, m.getMemoryDate(), m.getMood(), m.getContent()));
    }
    return sb.toString();
  }

  private String chatComplete(String userPrompt) {
    RestClient c = client();
    String systemPrompt = "你是一个温暖治愈的记忆助手。请阅读以下用户近期记录的记忆片段，" +
        "生成一段150字以内的温情总结，提炼出这段时间的关键事件和情绪变化。" +
        "同时给出一个诗意标题和1-3个情绪标签。" +
        "请严格按JSON格式返回，不要包含其他内容，不要用markdown代码块包裹：" +
        "{\"title\": \"...\", \"summary\": \"...\", \"moodTags\": [\"...\"]}";

    try {
      List<Map<String, String>> messages = List.of(
          Map.of("role", "system", "content", systemPrompt),
          Map.of("role", "user", "content", userPrompt)
      );
      Map<String, Object> body = Map.of(
          "model", aiConfig.chatModel(),
          "messages", messages,
          "temperature", 0.7,
          "max_tokens", 800
      );
      Map resp = c.post().uri("/chat/completions").body(body).retrieve().body(Map.class);
      if (resp == null) throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 接口返回空响应");
      List<Map<String, Object>> choices = (List<Map<String, Object>>) resp.get("choices");
      Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
      return (String) message.get("content");
    } catch (ApiException e) {
      throw e;
    } catch (Exception e) {
      log.error("Recall summary AI error: {}", e.getMessage());
      throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 总结请求失败，请稍后重试");
    }
  }

  private SummaryResult parseResponse(String rawJson) {
    try {
      String json = rawJson.trim();
      if (json.startsWith("```")) {
        json = json.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();
      }
      Map<String, Object> map = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
      String title = (String) map.getOrDefault("title", "回忆总结");
      String summary = (String) map.getOrDefault("summary", "");
      List<String> moodTags = (List<String>) map.getOrDefault("moodTags", List.of());
      return new SummaryResult(title, summary, moodTags);
    } catch (Exception e) {
      log.error("Failed to parse AI summary response: {}", rawJson);
      return new SummaryResult("回忆总结", rawJson.length() > 200 ? rawJson.substring(0, 200) + "..." : rawJson, List.of());
    }
  }

  private RestClient client() {
    if (this.client == null) {
      this.client = RestClient.builder()
          .baseUrl(aiConfig.baseUrl())
          .defaultHeader("Authorization", "Bearer " + aiConfig.apiKey())
          .defaultHeader("Content-Type", "application/json")
          .build();
    }
    return this.client;
  }
}
