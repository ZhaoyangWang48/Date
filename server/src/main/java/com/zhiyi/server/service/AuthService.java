package com.zhiyi.server.service;

import com.zhiyi.server.api.*;
import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.*;
import com.zhiyi.server.domain.UserAccount;
import com.zhiyi.server.repository.UserRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @Transactional
public class AuthService {
  private final UserRepository users; private final PasswordEncoder encoder; private final JwtService jwt;
  public AuthService(UserRepository users, PasswordEncoder encoder, JwtService jwt) { this.users = users; this.encoder = encoder; this.jwt = jwt; }
  public AuthResponse register(RegisterRequest request) {
    String username = request.username().trim();
    if (users.findByUsername(username).isPresent()) throw new ApiException(HttpStatus.CONFLICT, "该用户名已被注册");
    UserAccount user = users.save(new UserAccount(username, encoder.encode(request.password()), request.nickname().trim()));
    return new AuthResponse(jwt.create(UserPrincipal.from(user)), UserResponse.from(user));
  }
  @Transactional(readOnly = true) public AuthResponse login(LoginRequest request) {
    UserAccount user = users.findByUsername(request.username().trim()).orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "用户名或密码不正确"));
    if (!encoder.matches(request.password(), user.getPasswordHash())) throw new ApiException(HttpStatus.UNAUTHORIZED, "用户名或密码不正确");
    return new AuthResponse(jwt.create(UserPrincipal.from(user)), UserResponse.from(user));
  }
  @Transactional(readOnly = true) public UserResponse me(UserPrincipal principal) { return UserResponse.from(requireUser(principal.id())); }
  public UserAccount requireUser(Long id) { return users.findById(id).orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "登录用户不存在")); }
}
