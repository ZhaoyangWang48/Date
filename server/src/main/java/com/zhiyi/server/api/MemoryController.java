package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.MemoryService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController @RequestMapping("/api/memories")
public class MemoryController {
  private final MemoryService service;
  public MemoryController(MemoryService service) { this.service = service; }
  @GetMapping public ApiResponse<List<MemoryResponse>> list(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.personal(principal)); }
  @PostMapping @ResponseStatus(HttpStatus.CREATED) public ApiResponse<MemoryResponse> create(@AuthenticationPrincipal UserPrincipal principal, @Valid @RequestBody MemoryRequest request) { return ApiResponse.ok("记忆已种下", service.create(principal, request)); }
  @GetMapping("/{id}") public ApiResponse<MemoryResponse> get(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("success", service.get(principal, id)); }
  @PatchMapping("/{id}") public ApiResponse<MemoryResponse> update(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id, @Valid @RequestBody MemoryUpdateRequest request) { return ApiResponse.ok("记忆已更新", service.update(principal, id, request)); }
  @DeleteMapping("/{id}") public ApiResponse<Void> delete(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { service.delete(principal, id); return ApiResponse.ok("记忆已删除", null); }
}
