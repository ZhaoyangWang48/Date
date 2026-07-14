package com.zhiyi.server.repository;

import com.zhiyi.server.domain.BottleResonanceEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface BottleResonanceRepository extends JpaRepository<BottleResonanceEntity, Long> {
  boolean existsByBottleIdAndResponderId(Long bottleId, Long responderId);
  long countByBottleId(Long bottleId);
  List<BottleResonanceEntity> findByBottleAuthorIdOrderByCreatedAtDesc(Long authorId);
}
