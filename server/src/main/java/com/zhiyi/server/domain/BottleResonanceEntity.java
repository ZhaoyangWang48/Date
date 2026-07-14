package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "bottle_resonances", uniqueConstraints = @UniqueConstraint(columnNames = {"bottle_id", "responder_id"}))
public class BottleResonanceEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "bottle_id", nullable = false) private DriftBottleEntity bottle;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "responder_id", nullable = false) private UserAccount responder;
  @Column(nullable = false, length = 30) private String mood;
  @Column(name = "created_at", nullable = false) private LocalDateTime createdAt;
  protected BottleResonanceEntity() { }
  public BottleResonanceEntity(DriftBottleEntity bottle, UserAccount responder, String mood) { this.bottle = bottle; this.responder = responder; this.mood = mood; this.createdAt = LocalDateTime.now(); }
  public Long getId() { return id; }
  public DriftBottleEntity getBottle() { return bottle; }
  public String getMood() { return mood; }
  public LocalDateTime getCreatedAt() { return createdAt; }
}
