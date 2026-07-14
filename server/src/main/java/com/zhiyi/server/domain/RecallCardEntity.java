package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "recall_cards")
public class RecallCardEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private UserAccount user;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tree_hole_id") private TreeHoleEntity treeHole;
  @Column(nullable = false, length = 200) private String title;
  @Column(nullable = false, columnDefinition = "TEXT") private String summary;
  @Column(name = "mood_tags", length = 500) private String moodTags;
  @Column(name = "representative_image_url", length = 500) private String representativeImageUrl;
  @Column(name = "time_range_start", nullable = false) private LocalDate timeRangeStart;
  @Column(name = "time_range_end", nullable = false) private LocalDate timeRangeEnd;
  @Column(name = "memory_count", nullable = false) private int memoryCount;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;

  protected RecallCardEntity() { }

  public RecallCardEntity(UserAccount user, TreeHoleEntity treeHole, String title, String summary,
                          String moodTags, String representativeImageUrl, LocalDate timeRangeStart,
                          LocalDate timeRangeEnd, int memoryCount) {
    this.user = user;
    this.treeHole = treeHole;
    this.title = title;
    this.summary = summary;
    this.moodTags = moodTags;
    this.representativeImageUrl = representativeImageUrl;
    this.timeRangeStart = timeRangeStart;
    this.timeRangeEnd = timeRangeEnd;
    this.memoryCount = memoryCount;
  }

  @PrePersist void beforeInsert() { createdAt = LocalDateTime.now(); }

  public Long getId() { return id; }
  public UserAccount getUser() { return user; }
  public TreeHoleEntity getTreeHole() { return treeHole; }
  public String getTitle() { return title; }
  public String getSummary() { return summary; }
  public String getMoodTags() { return moodTags; }
  public String getRepresentativeImageUrl() { return representativeImageUrl; }
  public LocalDate getTimeRangeStart() { return timeRangeStart; }
  public LocalDate getTimeRangeEnd() { return timeRangeEnd; }
  public int getMemoryCount() { return memoryCount; }
  public LocalDateTime getCreatedAt() { return createdAt; }
}
