package com.zhiyi.server.domain;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "tree_members", uniqueConstraints = @UniqueConstraint(name = "uk_tree_members_tree_user", columnNames = {"tree_hole_id", "user_id"}))
public class TreeMemberEntity {
  @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "tree_hole_id", nullable = false) private TreeHoleEntity treeHole;
  @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id", nullable = false) private UserAccount user;
  @Enumerated(EnumType.STRING) @Column(nullable = false, length = 16) private MemberRole role;
  @Column(name = "joined_at", nullable = false) private LocalDateTime joinedAt;
  protected TreeMemberEntity() { }
  public TreeMemberEntity(TreeHoleEntity treeHole, UserAccount user, MemberRole role) { this.treeHole = treeHole; this.user = user; this.role = role; }
  @PrePersist void beforeInsert() { joinedAt = LocalDateTime.now(); }
  public Long getId() { return id; }
  public TreeHoleEntity getTreeHole() { return treeHole; }
  public UserAccount getUser() { return user; }
  public MemberRole getRole() { return role; }
}
