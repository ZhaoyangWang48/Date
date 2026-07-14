package com.zhiyi.server.agent;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.api.Dtos;
import com.zhiyi.server.storage.FileStorageService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.io.IOException;
import java.time.Duration;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class MemoryDraftService {
  private static final Logger log = LoggerFactory.getLogger(MemoryDraftService.class);
  private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;
  private static final DateTimeFormatter TIME_FORMAT = DateTimeFormatter.ofPattern("yyyy年M月d日 HH:mm");
  private static final String SYSTEM_PROMPT = """
    你是一位克制、温暖的中文记忆撰写助手。请观察照片，并结合照片拍摄时间，写一段可由用户继续修改的第一人称记忆草稿。
    要求：80至140个汉字；语言自然、有画面感；可以描述可见的场景、氛围和感受；不要编造具体的人名、地点、关系或事件；
    无法确定的内容使用“像是”“也许”等克制表达；不要使用标题、Markdown、引号或解释，只输出草稿正文。
    """;

  private final KimiConfigProperties config;
  private final FileStorageService storage;
  private final ObjectMapper objectMapper;
  private RestClient client;

  public MemoryDraftService(KimiConfigProperties config, FileStorageService storage, ObjectMapper objectMapper) {
    this.config = config;
    this.storage = storage;
    this.objectMapper = objectMapper;
  }

  public Dtos.MemoryDraftResponse generate(String imageUrl, java.time.LocalDateTime capturedAt) {
    ensureConfigured();
    byte[] image = readUploadedImage(imageUrl);
    String dataUri = "data:" + mimeType(imageUrl) + ";base64," + Base64.getEncoder().encodeToString(image);

    Map<String, Object> imagePart = Map.of(
      "type", "image_url",
      "image_url", Map.of("url", dataUri)
    );
    Map<String, Object> textPart = Map.of(
      "type", "text",
      "text", "这张照片的拍摄时间是 " + capturedAt.format(TIME_FORMAT) + "。请只返回中文记忆草稿正文。"
    );
    List<Map<String, Object>> messages = List.of(
      Map.of("role", "system", "content", SYSTEM_PROMPT),
      Map.of("role", "user", "content", List.of(imagePart, textPart))
    );

    Map<String, Object> body = new LinkedHashMap<>();
    body.put("model", config.model());
    body.put("messages", messages);
    // 关闭扩展思考可避免简短草稿请求把输出额度全部消耗在 reasoning_content 中。
    body.put("thinking", Map.of("type", "disabled"));
    // kimi-for-coding 当前仅接受 0.6；其他温度会被接口拒绝。
    body.put("temperature", 0.6);
    body.put("max_tokens", 600);

    try {
      JsonNode response = client().post()
        .uri("/chat/completions")
        .body(body)
        .retrieve()
        .body(JsonNode.class);
      String content = response == null ? "" : response.path("choices").path(0)
        .path("message").path("content").asText("").trim();
      if (content.isEmpty()) {
        throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型未返回记忆草稿，请重试");
      }
      return new Dtos.MemoryDraftResponse(content);
    } catch (ApiException error) {
      throw error;
    } catch (RestClientResponseException error) {
      log.warn("Kimi request failed with HTTP {}: {}", error.getStatusCode().value(), upstreamError(error));
      if (error.getStatusCode().value() == 401) {
        throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型服务配置无效或无权使用当前模型");
      }
      if (error.getStatusCode().value() == 403 || error.getStatusCode().value() == 429) {
        throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "大模型调用额度不足或请求过于频繁，请稍后再试");
      }
      throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型图片识别失败，请稍后重试");
    } catch (ResourceAccessException error) {
      log.warn("Kimi request timed out or could not connect: {}", error.getClass().getSimpleName());
      throw new ApiException(HttpStatus.GATEWAY_TIMEOUT, "大模型响应超时，请稍后重试");
    } catch (Exception error) {
      log.warn("Unexpected Kimi response: {}", error.getClass().getSimpleName());
      throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型图片识别失败，请稍后重试");
    }
  }

  private void ensureConfigured() {
    if (config.apiKey() == null || config.apiKey().isBlank()) {
      throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
        "大模型服务未配置，请联系管理员");
    }
  }

  private byte[] readUploadedImage(String imageUrl) {
    try {
      byte[] image = storage.read(imageUrl);
      if (image.length == 0 || image.length > MAX_IMAGE_BYTES) {
        throw new ApiException(HttpStatus.BAD_REQUEST, "图片为空或超过 10MB");
      }
      return image;
    } catch (ApiException error) {
      throw error;
    } catch (IOException error) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "图片不存在或地址无效，请重新上传");
    }
  }

  private String mimeType(String imageUrl) {
    String lower = imageUrl.toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }

  private String upstreamError(RestClientResponseException error) {
    try {
      String message = objectMapper.readTree(error.getResponseBodyAsString())
        .path("error").path("message").asText("upstream rejected the request");
      return message.length() > 240 ? message.substring(0, 240) : message;
    } catch (Exception ignored) {
      return "upstream rejected the request";
    }
  }

  private RestClient client() {
    if (client == null) {
      SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
      requestFactory.setConnectTimeout(Duration.ofSeconds(10));
      requestFactory.setReadTimeout(Duration.ofSeconds(90));
      client = RestClient.builder()
        .requestFactory(requestFactory)
        .baseUrl(config.baseUrl())
        .defaultHeader("Authorization", "Bearer " + config.apiKey())
        .defaultHeader("Content-Type", "application/json")
        .defaultHeader("User-Agent", "Zhiyi-Memory/1.6")
        .build();
    }
    return client;
  }
}
