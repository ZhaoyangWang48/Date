package com.zhiyi.server.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.zhiyi.server.api.ApiResponse;
import com.zhiyi.server.auth.JwtAuthenticationFilter;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.*;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration @EnableWebSecurity
public class SecurityConfig {
  @Bean PasswordEncoder passwordEncoder() { return new BCryptPasswordEncoder(); }
  @Bean SecurityFilterChain securityFilterChain(HttpSecurity http, JwtAuthenticationFilter jwt, ObjectMapper mapper) throws Exception {
    return http.csrf(csrf -> csrf.disable()).sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
      .authorizeHttpRequests(auth -> auth.requestMatchers("/api/auth/**", "/uploads/**", "/swagger-ui/**", "/swagger-ui.html", "/v3/api-docs/**").permitAll().anyRequest().authenticated())
      .exceptionHandling(errors -> errors.authenticationEntryPoint((req, res, ex) -> write(mapper, res, 401, "登录已失效，请重新登录")).accessDeniedHandler((req, res, ex) -> write(mapper, res, 403, "没有权限执行此操作")))
      .addFilterBefore(jwt, UsernamePasswordAuthenticationFilter.class).build();
  }
  private void write(ObjectMapper mapper, HttpServletResponse response, int status, String message) throws java.io.IOException { response.setStatus(status); response.setContentType(MediaType.APPLICATION_JSON_VALUE); mapper.writeValue(response.getOutputStream(), ApiResponse.error(status, message)); }
}
