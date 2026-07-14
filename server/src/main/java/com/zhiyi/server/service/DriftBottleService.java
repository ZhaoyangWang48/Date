package com.zhiyi.server.service;

import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.domain.*;
import com.zhiyi.server.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.concurrent.ThreadLocalRandom;

@Service
@Transactional
public class DriftBottleService {
  private static final int DAILY_LIMIT = 3;
  private final DriftBottleRepository bottles; private final BottlePickupRepository pickups; private final BottleResonanceRepository resonances;
  private final MemoryRepository memories; private final AuthService auth;
  public DriftBottleService(DriftBottleRepository bottles, BottlePickupRepository pickups, BottleResonanceRepository resonances, MemoryRepository memories, AuthService auth) {
    this.bottles = bottles; this.pickups = pickups; this.resonances = resonances; this.memories = memories; this.auth = auth;
  }
  public DriftBottleResponse throwBottle(UserPrincipal principal, ThrowBottleRequest request) {
    if (dailyThrows(principal.id()) >= DAILY_LIMIT) throw new ApiException(HttpStatus.CONFLICT, "今天最多扔出 3 个漂流瓶");
    UserAccount user = auth.requireUser(principal.id()); MemoryEntity memory = null;
    String content = request.content() == null ? "" : request.content().trim(); String mood = request.mood().trim();
    if (request.memoryId() != null && request.memoryId() > 0) {
      memory = memories.findById(request.memoryId()).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "关联记忆不存在"));
      if (!memory.getAuthor().getId().equals(principal.id()) || memory.getTreeHole() != null) throw new ApiException(HttpStatus.FORBIDDEN, "只能封存自己的个人记忆");
      if (content.isEmpty()) content = memory.getContent();
      if (mood.isEmpty()) mood = memory.getMood();
    }
    if (content.isEmpty()) throw new ApiException(HttpStatus.BAD_REQUEST, "请写下想投入海中的话");
    DriftBottleEntity bottle = bottles.save(new DriftBottleEntity(user, memory, content, mood));
    return DriftBottleResponse.from(bottle, 0);
  }
  public DriftBottleResponse pickup(UserPrincipal principal) {
    if (dailyPickups(principal.id()) >= DAILY_LIMIT) throw new ApiException(HttpStatus.CONFLICT, "今天最多捞取 3 个漂流瓶");
    List<DriftBottleEntity> choices = bottles.findByExpireAtAfterOrderByThrownAtDesc(LocalDateTime.now()).stream()
      .filter(b -> !b.getAuthor().getId().equals(principal.id()))
      .filter(b -> !pickups.existsByBottleIdAndUserId(b.getId(), principal.id())).toList();
    if (choices.isEmpty()) throw new ApiException(HttpStatus.NOT_FOUND, "海面暂时没有新的漂流瓶");
    DriftBottleEntity bottle = choices.get(ThreadLocalRandom.current().nextInt(choices.size()));
    pickups.save(new BottlePickupEntity(bottle, auth.requireUser(principal.id())));
    return DriftBottleResponse.anonymous(bottle);
  }
  public ResonanceLeafResponse resonate(UserPrincipal principal, Long bottleId, SendResonanceRequest request) {
    DriftBottleEntity bottle = bottles.findById(bottleId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "漂流瓶不存在"));
    if (bottle.getAuthor().getId().equals(principal.id())) throw new ApiException(HttpStatus.FORBIDDEN, "不能回应自己的漂流瓶");
    if (!pickups.existsByBottleIdAndUserId(bottleId, principal.id())) throw new ApiException(HttpStatus.FORBIDDEN, "请先捞起这个漂流瓶");
    if (resonances.existsByBottleIdAndResponderId(bottleId, principal.id())) throw new ApiException(HttpStatus.CONFLICT, "已经送出过共鸣叶");
    BottleResonanceEntity saved = resonances.save(new BottleResonanceEntity(bottle, auth.requireUser(principal.id()), request.mood().trim()));
    return ResonanceLeafResponse.from(saved);
  }
  @Transactional(readOnly = true) public List<DriftBottleResponse> mine(UserPrincipal principal) { return bottles.findByAuthorIdOrderByThrownAtDesc(principal.id()).stream().map(b -> DriftBottleResponse.from(b, resonances.countByBottleId(b.getId()))).toList(); }
  @Transactional(readOnly = true) public List<ResonanceLeafResponse> myResonances(UserPrincipal principal) { return resonances.findByBottleAuthorIdOrderByCreatedAtDesc(principal.id()).stream().map(ResonanceLeafResponse::from).toList(); }
  @Transactional(readOnly = true) public BottlePickupCountResponse pickupCount(UserPrincipal principal) { return new BottlePickupCountResponse(dailyPickups(principal.id())); }
  private long dailyThrows(Long userId) { LocalDateTime start = LocalDate.now().atStartOfDay(); return bottles.countByAuthorIdAndThrownAtGreaterThanEqualAndThrownAtLessThan(userId, start, start.plusDays(1)); }
  private long dailyPickups(Long userId) { LocalDateTime start = LocalDate.now().atStartOfDay(); return pickups.countByUserIdAndPickedAtGreaterThanEqualAndPickedAtLessThan(userId, start, start.plusDays(1)); }
}
