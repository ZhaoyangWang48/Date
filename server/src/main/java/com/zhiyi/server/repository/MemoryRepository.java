package com.zhiyi.server.repository;
import com.zhiyi.server.domain.MemoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.time.LocalDate;
import java.util.List;
public interface MemoryRepository extends JpaRepository<MemoryEntity, Long> {
  List<MemoryEntity> findByAuthorIdAndTreeHoleIsNullOrderByCreatedAtDesc(Long authorId);
  List<MemoryEntity> findByTreeHoleIdOrderByCreatedAtDesc(Long treeHoleId);
  List<MemoryEntity> findByTreeHoleIdAndMemoryDateOrderByMemoryHourAscCreatedAtAsc(Long treeHoleId, LocalDate memoryDate);
}
