package com.zhiyi.server.auth;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Date;

@Service
public class JwtService {
  private final SecretKey key;
  private final long expirationDays;
  public JwtService(@Value("${zhiyi.jwt.secret}") String secret, @Value("${zhiyi.jwt.expiration-days}") long expirationDays) {
    if (secret.length() < 32) throw new IllegalStateException("ZHIYI_JWT_SECRET 至少需要 32 个字符");
    this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8)); this.expirationDays = expirationDays;
  }
  public String create(UserPrincipal principal) { Instant now = Instant.now(); return Jwts.builder().subject(principal.username()).claim("uid", principal.id()).issuedAt(Date.from(now)).expiration(Date.from(now.plus(expirationDays, ChronoUnit.DAYS))).signWith(key).compact(); }
  public String username(String token) { return Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload().getSubject(); }
}
