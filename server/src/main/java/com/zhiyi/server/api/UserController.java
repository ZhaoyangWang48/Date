package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.UserResponse;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.AuthService;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/users")
public class UserController {
  private final AuthService service;
  public UserController(AuthService service) { this.service = service; }
  @GetMapping("/me") public ApiResponse<UserResponse> me(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", service.me(principal)); }
}
