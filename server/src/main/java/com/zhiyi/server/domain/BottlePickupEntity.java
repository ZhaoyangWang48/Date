package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "bottle_pickups", uniqueConstraints = @UniqueConstraint(columnNames = {"bottle_id", "user_id"}))
public class BottlePickupEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "bottle_id", nullable = false) private DriftBottleEntity bottle;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private UserAccount user;
  @Column(name = "picked_at", nullable = false) private LocalDateTime pickedAt;
  protected BottlePickupEntity() { }
  public BottlePickupEntity(DriftBottleEntity bottle, UserAccount user) { this.bottle = bottle; this.user = user; this.pickedAt = LocalDateTime.now(); }
  public DriftBottleEntity getBottle() { return bottle; }
}
