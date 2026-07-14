package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.DriftBottleService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/bottles")
public class DriftBottleController {
  private final DriftBottleService service;
  public DriftBottleController(DriftBottleService service) { this.service = service; }
  @PostMapping @ResponseStatus(HttpStatus.CREATED) public ApiResponse<DriftBottleResponse> throwBottle(@AuthenticationPrincipal UserPrincipal principal, @Valid @RequestBody ThrowBottleRequest request) { return ApiResponse.ok("漂流瓶已投入大海", service.throwBottle(principal, request)); }
  @GetMapping("/random") public ApiResponse<DriftBottleResponse> pickup(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("捞到了一个漂流瓶", service.pickup(principal)); }
  @PostMapping("/{id}/resonance") @ResponseStatus(HttpStatus.CREATED) public ApiResponse<ResonanceLeafResponse> resonate(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id, @Valid @RequestBody SendResonanceRequest request) { return ApiResponse.ok("共鸣叶已送出", service.resonate(principal, id, request)); }
  @GetMapping("/mine") public ApiResponse<List<DriftBottleResponse>> mine(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.mine(principal)); }
  @GetMapping("/mine/resonances") public ApiResponse<List<ResonanceLeafResponse>> resonances(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.myResonances(principal)); }
  @GetMapping("/pickup-count") public ApiResponse<BottlePickupCountResponse> pickupCount(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.pickupCount(principal)); }
}
