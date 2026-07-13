package com.zhiyi.server.api;

import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.AuthService;
import com.zhiyi.server.service.RecallCardService;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/recall-cards")
public class RecallCardController {

  private final RecallCardService recallCardService;
  private final AuthService authService;

  public RecallCardController(RecallCardService recallCardService, AuthService authService) {
    this.recallCardService = recallCardService;
    this.authService = authService;
  }

  @PostMapping("/generate")
  public ApiResponse<Dtos.RecallCardResponse> generate(
      @AuthenticationPrincipal UserPrincipal principal,
      @Valid @RequestBody Dtos.GenerateRecallCardRequest request) {
    Long treeHoleId = request.treeHoleId() != null && request.treeHoleId() > 0 ? request.treeHoleId() : null;
    Dtos.RecallCardResponse card = recallCardService.generate(
        authService.requireUser(principal.id()), treeHoleId);
    if (card == null) {
      return ApiResponse.ok("no_new_memories", null);
    }
    return ApiResponse.ok("ok", card);
  }

  @GetMapping
  public ApiResponse<List<Dtos.RecallCardResponse>> list(
      @AuthenticationPrincipal UserPrincipal principal,
      @RequestParam(required = false) Long treeHoleId) {
    Long thId = treeHoleId != null && treeHoleId > 0 ? treeHoleId : null;
    return ApiResponse.ok("ok", recallCardService.list(
        authService.requireUser(principal.id()), thId));
  }

  @GetMapping("/{id}")
  public ApiResponse<Dtos.RecallCardResponse> detail(@PathVariable Long id) {
    return ApiResponse.ok("ok", recallCardService.detail(id));
  }
}
