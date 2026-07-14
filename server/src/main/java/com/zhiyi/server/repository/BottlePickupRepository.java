package com.zhiyi.server.repository;

import com.zhiyi.server.domain.BottlePickupEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;

public interface BottlePickupRepository extends JpaRepository<BottlePickupEntity, Long> {
  boolean existsByBottleIdAndUserId(Long bottleId, Long userId);
  long countByUserIdAndPickedAtGreaterThanEqualAndPickedAtLessThan(Long userId, LocalDateTime start, LocalDateTime end);
}
