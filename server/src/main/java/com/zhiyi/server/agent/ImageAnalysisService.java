package com.zhiyi.server.agent;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.storage.EnhanceParams;
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
import java.util.*;

@Service
public class ImageAnalysisService {
  private static final Logger log = LoggerFactory.getLogger(ImageAnalysisService.class);
  private static final int MAX_IMAGE_BYTES = 10 * 1024 * 1024;

  private static final String SYSTEM_PROMPT = """
    你是一个图像质量分析助手。观察用户提供的照片，判断它在以下五个维度上的问题程度，并输出对应的增强参数 JSON。

    五个增强步骤及其参数说明：

    1. contrast（对比度拉伸）— lowClip 和 highClip 是直方图截断百分位。
       图片偏灰/发雾时降低 lowClip（如 0.01）、提高 highClip（如 0.99）；
       图片对比度正常则保持默认 lowClip=0.02, highClip=0.98。
       范围：lowClip 0.0-0.1, highClip 0.9-1.0。

    2. brightness（亮度线性调整）— pixel * scale + offset。
       图片偏暗时提高 offset（5~15）；图片偏亮时降低 offset（-5~-15）或 scale（0.9~0.95）。
       默认 scale=1.05, offset=3。scale 范围 0.85-1.2, offset 范围 -20~20。

    3. denoise（双边滤波降噪）— radius（空间半径）、sigmaColor（颜色标准差）、sigmaSpace（空间标准差）。
       噪点明显时 radius 设为 3、sigmaColor 提高到 40~60；
       图片干净时 radius=1, sigmaColor=15~20 或更低。
       默认 radius=2, sigmaColor=25, sigmaSpace=2。radius 范围 1~4。

    4. sharpen（反锐化掩模锐化）— amount（强度）、blurSigma（模糊半径）、threshold（忽略阈值）。
       图片模糊时提高 amount（0.8~1.2）、blurSigma（2.0~3.0）；
       图片清晰时 amount=0.3~0.5。
       默认 amount=0.5, blurSigma=1.5, threshold=2。amount 范围 0.0~1.5。

    5. vibrance（鲜艳度增强，HSL 空间）— strength（强度）、lowSatThreshold（低饱和度阈值）、skinProtectFactor（肤色保护因子）。
       色彩暗淡时提高 strength（0.3~0.5）、降低 lowSatThreshold（0.2~0.3）；
       色彩已经鲜艳时 strength 设为 0.0~0.1。
       默认 strength=0.2, lowSatThreshold=0.4, skinProtectFactor=0.5。strength 范围 0.0~0.6。

    请只返回 JSON，不要包含解释、markdown 代码块或任何其他文字：
    {"contrastLowClip":0.02,"contrastHighClip":0.98,"brightnessScale":1.05,"brightnessOffset":3,"denoiseRadius":2,"denoiseSigmaColor":25,"denoiseSigmaSpace":2,"sharpenAmount":0.5,"sharpenBlurSigma":1.5,"sharpenThreshold":2,"vibranceStrength":0.2,"vibranceLowSatThreshold":0.4,"vibranceSkinProtectFactor":0.5,"analysis":"用中文简短描述你观察到的图像问题和调整思路，30字以内"}
    """;

  private final KimiConfigProperties config;
  private final FileStorageService storage;
  private final ObjectMapper objectMapper;
  private RestClient client;

  public ImageAnalysisService(KimiConfigProperties config, FileStorageService storage, ObjectMapper objectMapper) {
    this.config = config;
    this.storage = storage;
    this.objectMapper = objectMapper;
  }

  public record AnalysisResult(EnhanceParams params, String analysis) {}

  public AnalysisResult analyze(String imageUrl) {
    ensureConfigured();
    byte[] image = readImage(imageUrl);
    String dataUri = "data:" + mimeType(imageUrl) + ";base64," + Base64.getEncoder().encodeToString(image);

    Map<String, Object> imagePart = Map.of(
        "type", "image_url",
        "image_url", Map.of("url", dataUri)
    );
    Map<String, Object> textPart = Map.of(
        "type", "text",
        "text", "请分析这张照片的图像质量问题，给出增强参数建议。"
    );
    List<Map<String, Object>> messages = List.of(
        Map.of("role", "system", "content", SYSTEM_PROMPT),
        Map.of("role", "user", "content", List.of(imagePart, textPart))
    );

    Map<String, Object> body = new LinkedHashMap<>();
    body.put("model", config.model());
    body.put("messages", messages);
    body.put("thinking", Map.of("type", "disabled"));
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
        throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型未返回分析结果，请重试");
      }
      return parseResponse(content);
    } catch (ApiException e) {
      throw e;
    } catch (RestClientResponseException e) {
      log.warn("Kimi analysis failed with HTTP {}: {}", e.getStatusCode().value(), e.getMessage());
      if (e.getStatusCode().value() == 401) {
        throw new ApiException(HttpStatus.BAD_GATEWAY, "大模型服务配置无效或无权使用当前模型");
      }
      if (e.getStatusCode().value() == 403 || e.getStatusCode().value() == 429) {
        throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "大模型调用额度不足或请求过于频繁，请稍后再试");
      }
      throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 图片分析失败，将使用默认参数增强");
    } catch (ResourceAccessException e) {
      log.warn("Kimi analysis timed out: {}", e.getClass().getSimpleName());
      throw new ApiException(HttpStatus.GATEWAY_TIMEOUT, "大模型响应超时，将使用默认参数增强");
    } catch (Exception e) {
      log.warn("Unexpected Kimi analysis error: {}", e.getClass().getSimpleName());
      throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 图片分析失败，将使用默认参数增强");
    }
  }

  private AnalysisResult parseResponse(String raw) {
    try {
      String json = raw.trim();
      if (json.startsWith("```")) {
        json = json.replaceAll("```json\\s*", "").replaceAll("```\\s*", "").trim();
      }
      Map<String, Object> map = objectMapper.readValue(json, new TypeReference<Map<String, Object>>() {});
      EnhanceParams params = new EnhanceParams(
          toDouble(map, "contrastLowClip", EnhanceParams.DEFAULT.contrastLowClip()),
          toDouble(map, "contrastHighClip", EnhanceParams.DEFAULT.contrastHighClip()),
          toFloat(map, "brightnessScale", EnhanceParams.DEFAULT.brightnessScale()),
          toFloat(map, "brightnessOffset", EnhanceParams.DEFAULT.brightnessOffset()),
          toInt(map, "denoiseRadius", EnhanceParams.DEFAULT.denoiseRadius()),
          toDouble(map, "denoiseSigmaColor", EnhanceParams.DEFAULT.denoiseSigmaColor()),
          toDouble(map, "denoiseSigmaSpace", EnhanceParams.DEFAULT.denoiseSigmaSpace()),
          toFloat(map, "sharpenAmount", EnhanceParams.DEFAULT.sharpenAmount()),
          toFloat(map, "sharpenBlurSigma", EnhanceParams.DEFAULT.sharpenBlurSigma()),
          toInt(map, "sharpenThreshold", EnhanceParams.DEFAULT.sharpenThreshold()),
          toFloat(map, "vibranceStrength", EnhanceParams.DEFAULT.vibranceStrength()),
          toFloat(map, "vibranceLowSatThreshold", EnhanceParams.DEFAULT.vibranceLowSatThreshold()),
          toFloat(map, "vibranceSkinProtectFactor", EnhanceParams.DEFAULT.vibranceSkinProtectFactor())
      );
      String analysis = map.getOrDefault("analysis", "").toString();
      return new AnalysisResult(params, analysis);
    } catch (Exception e) {
      log.warn("Failed to parse Kimi analysis response, using defaults: {}", e.getMessage());
      return new AnalysisResult(EnhanceParams.DEFAULT, "使用默认增强参数");
    }
  }

  private void ensureConfigured() {
    if (config.apiKey() == null || config.apiKey().isBlank()) {
      throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE, "大模型服务未配置，无法进行智能增强");
    }
  }

  private byte[] readImage(String imageUrl) {
    try {
      byte[] image = storage.read(imageUrl);
      if (image.length == 0 || image.length > MAX_IMAGE_BYTES) {
        throw new ApiException(HttpStatus.BAD_REQUEST, "图片为空或超过 10MB");
      }
      return image;
    } catch (ApiException e) {
      throw e;
    } catch (IOException e) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "图片不存在或地址无效，请重新上传");
    }
  }

  private String mimeType(String imageUrl) {
    String lower = imageUrl.toLowerCase();
    if (lower.endsWith(".png")) return "image/png";
    if (lower.endsWith(".webp")) return "image/webp";
    return "image/jpeg";
  }

  private double toDouble(Map<String, Object> map, String key, double def) {
    Object v = map.get(key);
    if (v instanceof Number n) return n.doubleValue();
    return def;
  }

  private float toFloat(Map<String, Object> map, String key, float def) {
    Object v = map.get(key);
    if (v instanceof Number n) return n.floatValue();
    return def;
  }

  private int toInt(Map<String, Object> map, String key, int def) {
    Object v = map.get(key);
    if (v instanceof Number n) return n.intValue();
    return def;
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
          .defaultHeader("User-Agent", "Zhiyi-ImageEnhance/1.0")
          .build();
    }
    return client;
  }
}
