package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/auth")
public class AuthController {
  private final AuthService service;
  public AuthController(AuthService service) { this.service = service; }
  @PostMapping("/register") public ApiResponse<AuthResponse> register(@Valid @RequestBody RegisterRequest request) { return ApiResponse.ok("注册成功", service.register(request)); }
  @PostMapping("/login") public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) { return ApiResponse.ok("登录成功", service.login(request)); }
}
