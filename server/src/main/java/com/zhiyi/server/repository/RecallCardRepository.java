package com.zhiyi.server.repository;

import com.zhiyi.server.domain.RecallCardEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;

public interface RecallCardRepository extends JpaRepository<RecallCardEntity, Long> {
  List<RecallCardEntity> findByUserIdAndTreeHoleIsNullOrderByCreatedAtDesc(Long userId);
  List<RecallCardEntity> findByUserIdAndTreeHoleIdOrderByCreatedAtDesc(Long userId, Long treeHoleId);
  Optional<RecallCardEntity> findFirstByUserIdAndTreeHoleIsNullOrderByCreatedAtDesc(Long userId);
}
