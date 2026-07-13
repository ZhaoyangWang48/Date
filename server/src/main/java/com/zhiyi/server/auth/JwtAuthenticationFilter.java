package com.zhiyi.server.auth;

import com.zhiyi.server.repository.UserRepository;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.*;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import java.io.IOException;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
  private final JwtService jwtService; private final UserRepository users;
  public JwtAuthenticationFilter(JwtService jwtService, UserRepository users) { this.jwtService = jwtService; this.users = users; }
  @Override protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain chain) throws ServletException, IOException {
    String header = request.getHeader("Authorization");
    if (header == null || !header.startsWith("Bearer ")) { chain.doFilter(request, response); return; }
    try {
      String username = jwtService.username(header.substring(7));
      users.findByUsername(username).ifPresent(user -> {
        UserPrincipal principal = UserPrincipal.from(user);
        SecurityContextHolder.getContext().setAuthentication(new UsernamePasswordAuthenticationToken(principal, null, principal.getAuthorities()));
      });
    } catch (JwtException | IllegalArgumentException ignored) { SecurityContextHolder.clearContext(); }
    chain.doFilter(request, response);
  }
}
