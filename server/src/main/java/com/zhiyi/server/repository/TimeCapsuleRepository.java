package com.zhiyi.server.repository;

import com.zhiyi.server.domain.TimeCapsuleEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface TimeCapsuleRepository extends JpaRepository<TimeCapsuleEntity, Long> {
  List<TimeCapsuleEntity> findByAuthorIdOrderByOpenAtDesc(Long authorId);
}
