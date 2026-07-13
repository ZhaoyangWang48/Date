package com.zhiyi.server.repository;
import com.zhiyi.server.domain.TreeHoleEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;
public interface TreeHoleRepository extends JpaRepository<TreeHoleEntity, Long> { Optional<TreeHoleEntity> findByInviteCode(String inviteCode); boolean existsByInviteCode(String inviteCode); }
