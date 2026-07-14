package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "time_capsules")
public class TimeCapsuleEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "author_id", nullable = false) private UserAccount author;
  @Column(nullable = false, columnDefinition = "TEXT") private String content;
  @Column(nullable = false, length = 30) private String mood;
  @Column(name = "seal_date", nullable = false) private LocalDate sealDate;
  @Column(name = "open_date", nullable = false) private LocalDate openDate;
  @Column(name = "open_at", nullable = false) private LocalDateTime openAt;
  @Column(name = "actual_open_date") private LocalDate actualOpenDate;
  @Column(nullable = false) private boolean opened;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
  @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;

  protected TimeCapsuleEntity() { }
  public TimeCapsuleEntity(UserAccount author, String content, String mood, LocalDateTime sealedAt, LocalDateTime openAt) {
    this.author = author; this.content = content; this.mood = mood; this.sealDate = sealedAt.toLocalDate();
    this.openDate = openAt.toLocalDate(); this.openAt = openAt;
  }
  @PrePersist void beforeInsert() { createdAt = LocalDateTime.now(); updatedAt = createdAt; }
  @PreUpdate void beforeUpdate() { updatedAt = LocalDateTime.now(); }
  public void open(LocalDateTime openedAt) { opened = true; actualOpenDate = openedAt.toLocalDate(); }
  public Long getId() { return id; }
  public UserAccount getAuthor() { return author; }
  public String getContent() { return content; }
  public String getMood() { return mood; }
  public LocalDate getSealDate() { return sealDate; }
  public LocalDate getOpenDate() { return openDate; }
  public LocalDateTime getOpenAt() { return openAt; }
  public LocalDate getActualOpenDate() { return actualOpenDate; }
  public boolean isOpened() { return opened; }
}
