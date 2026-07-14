package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "drift_bottles")
public class DriftBottleEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "author_id", nullable = false) private UserAccount author;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "memory_id") private MemoryEntity memory;
  @Column(nullable = false, columnDefinition = "TEXT") private String content;
  @Column(nullable = false, length = 30) private String mood;
  @Column(name = "thrown_at", nullable = false) private LocalDateTime thrownAt;
  @Column(name = "expire_at", nullable = false) private LocalDateTime expireAt;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;

  protected DriftBottleEntity() { }
  public DriftBottleEntity(UserAccount author, MemoryEntity memory, String content, String mood) {
    this.author = author; this.memory = memory; this.content = content; this.mood = mood;
    this.thrownAt = LocalDateTime.now(); this.expireAt = thrownAt.plusDays(3);
  }
  @PrePersist void beforeInsert() { if (createdAt == null) createdAt = LocalDateTime.now(); }
  public Long getId() { return id; }
  public UserAccount getAuthor() { return author; }
  public MemoryEntity getMemory() { return memory; }
  public String getContent() { return content; }
  public String getMood() { return mood; }
  public LocalDateTime getThrownAt() { return thrownAt; }
  public LocalDateTime getExpireAt() { return expireAt; }
}
