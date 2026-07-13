package com.zhiyi.server.repository;

import com.zhiyi.server.domain.MemoryEmbeddingEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface MemoryEmbeddingRepository extends JpaRepository<MemoryEmbeddingEntity, Long> {
    Optional<MemoryEmbeddingEntity> findByMemoryIdAndEmbeddingModel(Long memoryId, String embeddingModel);
}
