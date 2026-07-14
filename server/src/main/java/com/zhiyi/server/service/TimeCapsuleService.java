package com.zhiyi.server.service;

import com.zhiyi.server.api.ApiException;
import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.domain.TimeCapsuleEntity;
import com.zhiyi.server.repository.TimeCapsuleRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Clock;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class TimeCapsuleService {
  private final TimeCapsuleRepository capsules;
  private final AuthService auth;
  private final Clock clock;
  public TimeCapsuleService(TimeCapsuleRepository capsules, AuthService auth, Clock clock) {
    this.capsules = capsules; this.auth = auth; this.clock = clock;
  }

  public TimeCapsuleResponse create(UserPrincipal principal, CreateTimeCapsuleRequest request) {
    LocalDateTime now = LocalDateTime.now(clock);
    LocalDateTime openAt = request.openAt();
    if (openAt == null && request.openDate() != null) openAt = request.openDate().atTime(9, 0);
    if (openAt == null) throw new ApiException(HttpStatus.BAD_REQUEST, "请选择胶囊开启时间");
    if (!openAt.isAfter(now)) throw new ApiException(HttpStatus.BAD_REQUEST, "开启时间必须晚于当前时间");
    TimeCapsuleEntity capsule = capsules.save(new TimeCapsuleEntity(auth.requireUser(principal.id()), request.content().trim(), request.mood().trim(), now, openAt));
    return TimeCapsuleResponse.from(capsule);
  }
  @Transactional(readOnly = true) public List<TimeCapsuleResponse> list(UserPrincipal principal) { return capsules.findByAuthorIdOrderByOpenAtDesc(principal.id()).stream().map(TimeCapsuleResponse::from).toList(); }
  @Transactional(readOnly = true) public TimeCapsuleResponse get(UserPrincipal principal, Long id) { return TimeCapsuleResponse.from(requireOwner(principal, id)); }
  public TimeCapsuleResponse open(UserPrincipal principal, Long id) {
    TimeCapsuleEntity capsule = requireOwner(principal, id);
    if (capsule.isOpened()) return TimeCapsuleResponse.from(capsule);
    LocalDateTime now = LocalDateTime.now(clock);
    if (capsule.getOpenAt().isAfter(now)) throw new ApiException(HttpStatus.CONFLICT, "胶囊还未到开启时间");
    capsule.open(now);
    return TimeCapsuleResponse.from(capsule);
  }
  private TimeCapsuleEntity requireOwner(UserPrincipal principal, Long id) {
    TimeCapsuleEntity capsule = capsules.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "时光胶囊不存在"));
    if (!capsule.getAuthor().getId().equals(principal.id())) throw new ApiException(HttpStatus.FORBIDDEN, "无权访问这个时光胶囊");
    return capsule;
  }
}
