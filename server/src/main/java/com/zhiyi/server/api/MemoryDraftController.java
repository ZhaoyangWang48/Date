package com.zhiyi.server.api;

import com.zhiyi.server.agent.MemoryDraftService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/ai")
public class MemoryDraftController {
  private final MemoryDraftService memoryDraftService;

  public MemoryDraftController(MemoryDraftService memoryDraftService) {
    this.memoryDraftService = memoryDraftService;
  }

  @PostMapping("/memory-draft")
  public ApiResponse<Dtos.MemoryDraftResponse> generate(@Valid @RequestBody Dtos.MemoryDraftRequest request) {
    Dtos.MemoryDraftResponse response = memoryDraftService.generate(request.imageUrl(), request.capturedAt());
    return ApiResponse.ok("记忆草稿已生成", response);
  }
}
