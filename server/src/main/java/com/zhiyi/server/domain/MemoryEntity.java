package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "memories")
public class MemoryEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "author_id", nullable = false) private UserAccount author;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tree_hole_id") private TreeHoleEntity treeHole;
  @Column(nullable = false, columnDefinition = "TEXT") private String content;
  @Column(name = "image_url", length = 500) private String imageUrl;
  @Column(nullable = false, length = 30) private String mood;
  @Column(name = "memory_date", nullable = false) private LocalDate memoryDate;
  @Column(name = "memory_hour", nullable = false) private int memoryHour;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
  @Column(name = "updated_at", nullable = false) private LocalDateTime updatedAt;
  protected MemoryEntity() { }
  public MemoryEntity(UserAccount author, TreeHoleEntity treeHole, String content, String imageUrl, String mood, LocalDate memoryDate, int memoryHour) {
    this.author = author; this.treeHole = treeHole; this.content = content; this.imageUrl = imageUrl; this.mood = mood; this.memoryDate = memoryDate; this.memoryHour = memoryHour;
  }
  @PrePersist void beforeInsert() { createdAt = LocalDateTime.now(); updatedAt = createdAt; }
  @PreUpdate void beforeUpdate() { updatedAt = LocalDateTime.now(); }
  public void update(String content, String imageUrl, String mood, LocalDate date, int hour) { this.content = content; this.imageUrl = imageUrl; this.mood = mood; this.memoryDate = date; this.memoryHour = hour; }
  public Long getId() { return id; }
  public UserAccount getAuthor() { return author; }
  public TreeHoleEntity getTreeHole() { return treeHole; }
  public String getContent() { return content; }
  public String getImageUrl() { return imageUrl; }
  public String getMood() { return mood; }
  public LocalDate getMemoryDate() { return memoryDate; }
  public int getMemoryHour() { return memoryHour; }
  public LocalDateTime getCreatedAt() { return createdAt; }
}
