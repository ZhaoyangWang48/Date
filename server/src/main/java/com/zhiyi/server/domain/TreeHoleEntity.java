package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tree_holes")
public class TreeHoleEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @Column(nullable = false, length = 100) private String name;
  @Column(name = "invite_code", nullable = false, unique = true, length = 20) private String inviteCode;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "creator_id", nullable = false) private UserAccount creator;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
  @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
  protected TreeHoleEntity() { }
  public TreeHoleEntity(String name, String inviteCode, UserAccount creator) { this.name = name; this.inviteCode = inviteCode; this.creator = creator; }
  @PrePersist void beforeInsert() { createdAt = LocalDateTime.now(); updatedAt = createdAt; }
  @PreUpdate void beforeUpdate() { updatedAt = LocalDateTime.now(); }
  public Long getId() { return id; }
  public String getName() { return name; }
  public String getInviteCode() { return inviteCode; }
  public UserAccount getCreator() { return creator; }
  public LocalDateTime getCreatedAt() { return createdAt; }
}
