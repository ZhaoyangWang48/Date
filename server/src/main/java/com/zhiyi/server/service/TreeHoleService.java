package com.zhiyi.server.service;

import com.zhiyi.server.api.*;
import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.domain.*;
import com.zhiyi.server.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.security.SecureRandom;
import java.util.*;

@Service @Transactional
public class TreeHoleService {
  private static final char[] CODE = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
  private final TreeHoleRepository trees; private final TreeMemberRepository members; private final AuthService auth; private final SecureRandom random = new SecureRandom();
  public TreeHoleService(TreeHoleRepository trees, TreeMemberRepository members, AuthService auth) { this.trees = trees; this.members = members; this.auth = auth; }
  public TreeHoleResponse create(UserPrincipal principal, CreateTreeHoleRequest request) {
    UserAccount owner = auth.requireUser(principal.id()); TreeHoleEntity tree = trees.save(new TreeHoleEntity(request.name().trim(), nextCode(), owner));
    members.save(new TreeMemberEntity(tree, owner, MemberRole.OWNER)); return TreeHoleResponse.from(tree);
  }
  @Transactional(readOnly = true) public List<TreeHoleResponse> mine(UserPrincipal principal) { return members.findByUserIdOrderByTreeHoleCreatedAtDesc(principal.id()).stream().map(member -> TreeHoleResponse.from(member.getTreeHole())).toList(); }
  @Transactional(readOnly = true) public TreeHoleResponse detail(UserPrincipal principal, Long treeId) { return TreeHoleResponse.from(requireMember(principal, treeId).getTreeHole()); }
  public TreeHoleResponse join(UserPrincipal principal, JoinTreeHoleRequest request) {
    TreeHoleEntity tree = trees.findByInviteCode(request.inviteCode().trim().toUpperCase()).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "邀请码无效"));
    if (members.findByTreeHoleIdAndUserId(tree.getId(), principal.id()).isEmpty()) members.save(new TreeMemberEntity(tree, auth.requireUser(principal.id()), MemberRole.MEMBER));
    return TreeHoleResponse.from(tree);
  }
  @Transactional(readOnly = true) public List<TreeMemberResponse> members(UserPrincipal principal, Long treeId) { requireMember(principal, treeId); return members.findByTreeHoleIdOrderByJoinedAtAsc(treeId).stream().map(TreeMemberResponse::from).toList(); }
  public void removeMember(UserPrincipal principal, Long treeId, Long userId) {
    TreeMemberEntity acting = requireMember(principal, treeId);
    if (acting.getRole() != MemberRole.OWNER) throw new ApiException(HttpStatus.FORBIDDEN, "只有创建者可以管理成员");
    TreeMemberEntity target = members.findByTreeHoleIdAndUserId(treeId, userId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "成员不存在"));
    if (target.getRole() == MemberRole.OWNER) throw new ApiException(HttpStatus.CONFLICT, "不能移除树洞创建者");
    members.delete(target);
  }
  @Transactional(readOnly = true) public TreeMemberEntity requireMember(UserPrincipal principal, Long treeId) { return members.findByTreeHoleIdAndUserId(treeId, principal.id()).orElseThrow(() -> new ApiException(HttpStatus.FORBIDDEN, "你不是该树洞成员")); }
  @Transactional(readOnly = true) public TreeHoleEntity requireTree(Long treeId) { return trees.findById(treeId).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "树洞不存在")); }
  private String nextCode() { for (int attempt = 0; attempt < 10; attempt++) { StringBuilder value = new StringBuilder(); for (int i = 0; i < 6; i++) value.append(CODE[random.nextInt(CODE.length)]); if (!trees.existsByInviteCode(value.toString())) return value.toString(); } throw new ApiException(HttpStatus.INTERNAL_SERVER_ERROR, "邀请码生成失败"); }
}
