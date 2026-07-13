package com.zhiyi.server.api;

import com.zhiyi.server.domain.*;
import jakarta.validation.constraints.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

public final class Dtos {
  private Dtos() { }
  public record RegisterRequest(@NotBlank @Size(min = 3, max = 64) String username, @NotBlank @Size(min = 6, max = 128) String password, @NotBlank @Size(max = 64) String nickname) { }
  public record LoginRequest(@NotBlank String username, @NotBlank String password) { }
  public record CreateTreeHoleRequest(@NotBlank @Size(max = 100) String name) { }
  public record JoinTreeHoleRequest(@NotBlank @Size(max = 20) String inviteCode) { }
  public record MemoryRequest(@Size(max = 10000) String content, @Size(max = 500) String imageUrl, @NotBlank @Size(max = 30) String mood, @NotNull LocalDate date, @Min(0) @Max(23) Integer hour, Long treeHoleId) { }
  public record MemoryUpdateRequest(@Size(max = 10000) String content, @Size(max = 500) String imageUrl, @NotBlank @Size(max = 30) String mood, @NotNull LocalDate date, @Min(0) @Max(23) Integer hour) { }
  public record UserResponse(Long id, String username, String nickname, String avatarUrl) {
    public static UserResponse from(UserAccount user) { return new UserResponse(user.getId(), user.getUsername(), user.getNickname(), user.getAvatarUrl()); }
  }
  public record AuthResponse(String token, UserResponse user) { }
  public record TreeHoleResponse(Long id, String name, String inviteCode, Long creatorId, LocalDateTime createdAt) {
    public static TreeHoleResponse from(TreeHoleEntity tree) { return new TreeHoleResponse(tree.getId(), tree.getName(), tree.getInviteCode(), tree.getCreator().getId(), tree.getCreatedAt()); }
  }
  public record TreeMemberResponse(Long id, Long treeHoleId, Long userId, String nickname, String role) {
    public static TreeMemberResponse from(TreeMemberEntity member) { return new TreeMemberResponse(member.getId(), member.getTreeHole().getId(), member.getUser().getId(), member.getUser().getNickname(), member.getRole().name()); }
  }
  public record MemoryResponse(Long id, Long authorId, String authorName, Long treeHoleId, String content, String imageUrl, String mood, LocalDate date, int hour, LocalDateTime createdAt) {
    public static MemoryResponse from(MemoryEntity memory) { return new MemoryResponse(memory.getId(), memory.getAuthor().getId(), memory.getAuthor().getNickname(), memory.getTreeHole() == null ? 0L : memory.getTreeHole().getId(), memory.getContent(), memory.getImageUrl() == null ? "" : memory.getImageUrl(), memory.getMood(), memory.getMemoryDate(), memory.getMemoryHour(), memory.getCreatedAt()); }
  }
  public record ImageUploadResponse(String imageUrl) { }
}
