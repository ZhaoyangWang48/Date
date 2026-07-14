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
  public record ImageOptimizeResponse(String imageUrl, boolean optimized) { }
  public record MemoryDraftRequest(@NotBlank @Size(max = 500) String imageUrl, @NotNull LocalDateTime capturedAt) { }
  public record MemoryDraftResponse(String content) { }
  public record AgentChatRequest(@NotNull Long treeHoleId, @NotBlank @Size(max = 500) String question) { }
  public record AgentSourceCitation(Long memoryId, String contentSnippet, LocalDate date, String authorName) { }
  public record AgentChatResponse(String answer, java.util.List<AgentSourceCitation> sources) { }
  public record CreateTimeCapsuleRequest(@NotBlank @Size(max = 10000) String content, @NotBlank @Size(max = 30) String mood, LocalDateTime openAt, LocalDate openDate) { }
  public record TimeCapsuleResponse(Long id, Long authorId, String authorName, String content, String mood, LocalDate sealDate, LocalDate openDate, LocalDateTime openAt, LocalDate actualOpenDate, boolean isOpened) {
    public static TimeCapsuleResponse from(TimeCapsuleEntity capsule) { return new TimeCapsuleResponse(capsule.getId(), capsule.getAuthor().getId(), capsule.getAuthor().getNickname(), capsule.getContent(), capsule.getMood(), capsule.getSealDate(), capsule.getOpenDate(), capsule.getOpenAt(), capsule.getActualOpenDate(), capsule.isOpened()); }
  }
  public record ThrowBottleRequest(Long memoryId, @Size(max = 10000) String content, @NotBlank @Size(max = 30) String mood) { }
  public record SendResonanceRequest(@NotBlank @Size(max = 30) String mood) { }
  public record DriftBottleResponse(Long id, String content, String mood, LocalDateTime throwTime, LocalDateTime expireTime, boolean isPickedUp, long resonanceCount) {
    public static DriftBottleResponse from(DriftBottleEntity bottle, long resonanceCount) { return new DriftBottleResponse(bottle.getId(), bottle.getContent(), bottle.getMood(), bottle.getThrownAt(), bottle.getExpireAt(), false, resonanceCount); }
    public static DriftBottleResponse anonymous(DriftBottleEntity bottle) { return new DriftBottleResponse(bottle.getId(), bottle.getContent(), bottle.getMood(), bottle.getThrownAt(), bottle.getExpireAt(), true, 0); }
  }
  public record ResonanceLeafResponse(Long id, Long bottleId, String mood, LocalDateTime timestamp, String bottleContentSnippet) {
    public static ResonanceLeafResponse from(BottleResonanceEntity resonance) { String content = resonance.getBottle().getContent(); String snippet = content.length() > 36 ? content.substring(0, 36) + "…" : content; return new ResonanceLeafResponse(resonance.getId(), resonance.getBottle().getId(), resonance.getMood(), resonance.getCreatedAt(), snippet); }
  }
  public record BottlePickupCountResponse(long count) { }
  public record GenerateRecallCardRequest(Long treeHoleId) { }
  public record RecallCardResponse(Long id, Long userId, Long treeHoleId, String title, String summary, String moodTags, String representativeImageUrl, LocalDate timeRangeStart, LocalDate timeRangeEnd, int memoryCount, LocalDateTime createdAt) {
    public static RecallCardResponse from(RecallCardEntity card) {
      return new RecallCardResponse(card.getId(), card.getUser().getId(),
          card.getTreeHole() == null ? null : card.getTreeHole().getId(),
          card.getTitle(), card.getSummary(), card.getMoodTags(),
          card.getRepresentativeImageUrl(), card.getTimeRangeStart(),
          card.getTimeRangeEnd(), card.getMemoryCount(), card.getCreatedAt());
    }
  }
}
