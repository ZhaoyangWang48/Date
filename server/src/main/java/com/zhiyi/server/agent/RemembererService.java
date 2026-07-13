package com.zhiyi.server.agent;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.api.Dtos;
import com.zhiyi.server.domain.MemoryEmbeddingEntity;
import com.zhiyi.server.domain.MemoryEntity;
import com.zhiyi.server.repository.MemoryEmbeddingRepository;
import com.zhiyi.server.repository.MemoryRepository;
import com.zhiyi.server.service.TreeHoleService;
import com.zhiyi.server.auth.UserPrincipal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestClient;

import java.util.*;

@Service
@Transactional
public class RemembererService {

    private static final Logger log = LoggerFactory.getLogger(RemembererService.class);
    private static final int TOP_K = 5;

    private final MemoryRepository memoryRepo;
    private final MemoryEmbeddingRepository embeddingRepo;
    private final TreeHoleService treeHoleService;
    private final AiConfigProperties aiConfig;
    private final ObjectMapper objectMapper;
    private RestClient client;

    public RemembererService(MemoryRepository memoryRepo, MemoryEmbeddingRepository embeddingRepo,
                              TreeHoleService treeHoleService, AiConfigProperties aiConfig,
                              ObjectMapper objectMapper) {
        this.memoryRepo = memoryRepo;
        this.embeddingRepo = embeddingRepo;
        this.treeHoleService = treeHoleService;
        this.aiConfig = aiConfig;
        this.objectMapper = objectMapper;
    }

    public Dtos.AgentChatResponse chat(UserPrincipal principal, Long treeHoleId, String question) {
        treeHoleService.requireMember(principal, treeHoleId);

        if (aiConfig.apiKey() == null || aiConfig.apiKey().isBlank()) {
            throw new ApiException(HttpStatus.SERVICE_UNAVAILABLE,
                "AI 服务未配置，请在环境变量中设置 ZHIYI_AI_API_KEY");
        }

        RestClient c = client();

        List<MemoryEntity> memories = memoryRepo.findByTreeHoleIdOrderByCreatedAtDesc(treeHoleId);
        if (memories.isEmpty()) {
            return new Dtos.AgentChatResponse(
                "这个树洞还没有共享记忆呢～先一起创造一些回忆吧，我才能更好地守护它们 🌿",
                List.of());
        }

        boolean useEmbedding = aiConfig.embeddingModel() != null && !aiConfig.embeddingModel().isBlank();
        List<MemoryMatch> topK;
        if (useEmbedding) {
            double[] questionEmbedding = embed(c, question);
            topK = rankedMemories(c, memories, questionEmbedding, TOP_K);
        } else {
            topK = keywordSearch(memories, question, TOP_K);
        }

        String systemPrompt = """
            你是树洞的记忆守护者 Rememberer。请仅基于下面提供的树洞共享记忆来回答问题。
            回答要温暖、真诚、如朋友对话一般。如果记忆中没有相关信息，请诚实地说"我还不太了解这部分呢"。
            请用中文回答，控制在150字以内。""";

        StringBuilder ctx = new StringBuilder();
        for (int i = 0; i < topK.size(); i++) {
            MemoryEntity m = topK.get(i).memory;
            ctx.append(String.format("[%d] %s | %s的心情: %s | %s\n",
                i + 1, m.getMemoryDate(), m.getAuthor().getNickname(), m.getMood(), m.getContent()));
        }

        String answer = chatComplete(c, systemPrompt, ctx + "\n用户问题：" + question);

        List<Dtos.AgentSourceCitation> sources = topK.stream()
            .map(m -> {
                String snippet = m.memory.getContent();
                if (snippet.length() > 60) snippet = snippet.substring(0, 60) + "...";
                return new Dtos.AgentSourceCitation(
                    m.memory.getId(), snippet,
                    m.memory.getMemoryDate(), m.memory.getAuthor().getNickname());
            })
            .toList();

        return new Dtos.AgentChatResponse(answer, sources);
    }

    private List<MemoryMatch> rankedMemories(RestClient c, List<MemoryEntity> memories,
                                              double[] queryEmb, int k) {
        List<MemoryMatch> results = new ArrayList<>(memories.size());
        for (MemoryEntity mem : memories) {
            double[] memEmb = getOrComputeEmbedding(c, mem);
            double sim = cosine(queryEmb, memEmb);
            results.add(new MemoryMatch(mem, sim));
        }
        results.sort((a, b) -> Double.compare(b.similarity, a.similarity));
        return results.subList(0, Math.min(k, results.size()));
    }

    private List<MemoryMatch> keywordSearch(List<MemoryEntity> memories, String question, int k) {
        Set<String> tokens = new HashSet<>();
        for (int i = 0; i < question.length() - 1; i++) {
            tokens.add(question.substring(i, i + 2));
        }
        for (char c : question.toCharArray()) {
            tokens.add(String.valueOf(c));
        }

        List<MemoryMatch> results = new ArrayList<>(memories.size());
        for (MemoryEntity mem : memories) {
            String content = mem.getContent();
            int score = 0;
            for (String token : tokens) {
                if (token.length() > 1 && content.contains(token)) {
                    score += 3;
                } else if (content.contains(token)) {
                    score += 1;
                }
            }
            results.add(new MemoryMatch(mem, score));
        }
        results.sort((a, b) -> Double.compare(b.similarity, a.similarity));
        return results.subList(0, Math.min(k, results.size()));
    }

    private double[] getOrComputeEmbedding(RestClient c, MemoryEntity memory) {
        Optional<MemoryEmbeddingEntity> cached =
            embeddingRepo.findByMemoryIdAndEmbeddingModel(memory.getId(), aiConfig.embeddingModel());
        if (cached.isPresent()) {
            return parseEmbedding(cached.get().getEmbedding());
        }
        double[] vec = embed(c, memory.getContent());
        // Save outside transaction context — handled by caller's @Transactional
        try {
            String json = objectMapper.writeValueAsString(doublesToList(vec));
            embeddingRepo.save(new MemoryEmbeddingEntity(memory, json, aiConfig.embeddingModel()));
        } catch (Exception e) {
            log.warn("Failed to cache embedding for memory {}: {}", memory.getId(), e.getMessage());
        }
        return vec;
    }

    private double[] embed(RestClient c, String text) {
        try {
            Map<String, Object> body = Map.of(
                "model", aiConfig.embeddingModel(),
                "input", text
            );
            Map<String, Object> resp = c.post()
                .uri("/embeddings")
                .body(body)
                .retrieve()
                .body(Map.class);
            if (resp == null) throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 接口返回空响应");
            List<Map<String, Object>> data = (List<Map<String, Object>>) resp.get("data");
            List<Double> raw = (List<Double>) data.get(0).get("embedding");
            return raw.stream().mapToDouble(Double::doubleValue).toArray();
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Embedding API error: {}", e.getMessage());
            throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 服务请求失败，请检查 API Key 和网络连接");
        }
    }

    private String chatComplete(RestClient c, String systemPrompt, String userPrompt) {
        try {
            List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt)
            );
            Map<String, Object> body = Map.of(
                "model", aiConfig.chatModel(),
                "messages", messages,
                "temperature", 0.7,
                "max_tokens", 500
            );
            Map<String, Object> resp = c.post()
                .uri("/chat/completions")
                .body(body)
                .retrieve()
                .body(Map.class);
            if (resp == null) throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 接口返回空响应");
            List<Map<String, Object>> choices = (List<Map<String, Object>>) resp.get("choices");
            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            return (String) message.get("content");
        } catch (ApiException e) {
            throw e;
        } catch (Exception e) {
            log.error("Chat API error: {}", e.getMessage());
            throw new ApiException(HttpStatus.BAD_GATEWAY, "AI 对话请求失败，请稍后重试");
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

    private double cosine(double[] a, double[] b) {
        double dot = 0, na = 0, nb = 0;
        for (int i = 0; i < a.length; i++) {
            dot += a[i] * b[i];
            na += a[i] * a[i];
            nb += b[i] * b[i];
        }
        double denom = Math.sqrt(na) * Math.sqrt(nb);
        return denom == 0 ? 0 : dot / denom;
    }

    private double[] parseEmbedding(String json) {
        try {
            List<Double> list = objectMapper.readValue(json, new TypeReference<List<Double>>() {});
            return list.stream().mapToDouble(Double::doubleValue).toArray();
        } catch (Exception e) {
            throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "无法解析向量缓存");
        }
    }

    private static List<Double> doublesToList(double[] arr) {
        List<Double> list = new ArrayList<>(arr.length);
        for (double v : arr) list.add(v);
        return list;
    }

    private record MemoryMatch(MemoryEntity memory, double similarity) {}
}
