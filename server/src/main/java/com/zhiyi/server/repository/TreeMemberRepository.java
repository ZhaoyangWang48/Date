package com.zhiyi.server.repository;
import com.zhiyi.server.domain.TreeMemberEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;
import java.util.Optional;
public interface TreeMemberRepository extends JpaRepository<TreeMemberEntity, Long> {
  Optional<TreeMemberEntity> findByTreeHoleIdAndUserId(Long treeHoleId, Long userId);
  List<TreeMemberEntity> findByTreeHoleIdOrderByJoinedAtAsc(Long treeHoleId);
  List<TreeMemberEntity> findByUserIdOrderByTreeHoleCreatedAtDesc(Long userId);
}
