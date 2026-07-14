package com.zhiyi.server.repository;

import com.zhiyi.server.domain.DriftBottleEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDateTime;
import java.util.List;

public interface DriftBottleRepository extends JpaRepository<DriftBottleEntity, Long> {
  List<DriftBottleEntity> findByAuthorIdOrderByThrownAtDesc(Long authorId);
  List<DriftBottleEntity> findByExpireAtAfterOrderByThrownAtDesc(LocalDateTime time);
  long countByAuthorIdAndThrownAtGreaterThanEqualAndThrownAtLessThan(Long authorId, LocalDateTime start, LocalDateTime end);
}
