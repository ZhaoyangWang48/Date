package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.TimeCapsuleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/time-capsules")
public class TimeCapsuleController {
  private final TimeCapsuleService service;
  public TimeCapsuleController(TimeCapsuleService service) { this.service = service; }
  @PostMapping @ResponseStatus(HttpStatus.CREATED) public ApiResponse<TimeCapsuleResponse> create(@AuthenticationPrincipal UserPrincipal principal, @Valid @RequestBody CreateTimeCapsuleRequest request) { return ApiResponse.ok("时光胶囊已封存", service.create(principal, request)); }
  @GetMapping public ApiResponse<List<TimeCapsuleResponse>> list(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.list(principal)); }
  @GetMapping("/{id}") public ApiResponse<TimeCapsuleResponse> get(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("success", service.get(principal, id)); }
  @PatchMapping("/{id}/open") public ApiResponse<TimeCapsuleResponse> open(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("胶囊已开启", service.open(principal, id)); }
}
