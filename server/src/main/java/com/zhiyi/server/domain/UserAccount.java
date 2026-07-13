package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "users")
public class UserAccount {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @Column(nullable = false, unique = true, length = 64) private String username;
  @Column(name = "password_hash", nullable = false, length = 100) private String passwordHash;
  @Column(nullable = false, length = 64) private String nickname;
  @Column(name = "avatar_url", length = 500) private String avatarUrl;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
  @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

  protected UserAccount() { }
  public UserAccount(String username, String passwordHash, String nickname) {
    this.username = username; this.passwordHash = passwordHash; this.nickname = nickname;
  }
  @PrePersist void beforeInsert() { createdAt = LocalDateTime.now(); updatedAt = createdAt; }
  @PreUpdate void beforeUpdate() { updatedAt = LocalDateTime.now(); }
  public Long getId() { return id; }
  public String getUsername() { return username; }
  public String getPasswordHash() { return passwordHash; }
  public String getNickname() { return nickname; }
  public String getAvatarUrl() { return avatarUrl; }
}
