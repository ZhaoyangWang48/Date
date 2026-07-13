package com.zhiyi.server.service;

import com.zhiyi.server.api.*;
import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.domain.*;
import com.zhiyi.server.repository.MemoryRepository;
import com.zhiyi.server.storage.FileStorageService;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.util.List;

@Service @Transactional
public class MemoryService {
  private final MemoryRepository memories; private final AuthService auth; private final TreeHoleService trees; private final FileStorageService storage;
  public MemoryService(MemoryRepository memories, AuthService auth, TreeHoleService trees, FileStorageService storage) { this.memories = memories; this.auth = auth; this.trees = trees; this.storage = storage; }
  public MemoryResponse create(UserPrincipal principal, MemoryRequest request) {
    validateContent(request.content(), request.imageUrl()); TreeHoleEntity tree = null;
    if (request.treeHoleId() != null && request.treeHoleId() > 0) { trees.requireMember(principal, request.treeHoleId()); tree = trees.requireTree(request.treeHoleId()); }
    MemoryEntity memory = memories.save(new MemoryEntity(auth.requireUser(principal.id()), tree, normalized(request.content()), blankToNull(request.imageUrl()), request.mood().trim(), request.date(), request.hour()));
    return MemoryResponse.from(memory);
  }
  @Transactional(readOnly = true) public List<MemoryResponse> personal(UserPrincipal principal) { return memories.findByAuthorIdAndTreeHoleIsNullOrderByCreatedAtDesc(principal.id()).stream().map(MemoryResponse::from).toList(); }
  @Transactional(readOnly = true) public MemoryResponse get(UserPrincipal principal, Long id) { return MemoryResponse.from(requireVisible(principal, id)); }
  @Transactional(readOnly = true) public List<MemoryResponse> treeMemories(UserPrincipal principal, Long treeId) { trees.requireMember(principal, treeId); return memories.findByTreeHoleIdOrderByCreatedAtDesc(treeId).stream().map(MemoryResponse::from).toList(); }
  @Transactional(readOnly = true) public List<MemoryResponse> commonDay(UserPrincipal principal, Long treeId, LocalDate date) { trees.requireMember(principal, treeId); return memories.findByTreeHoleIdAndMemoryDateOrderByMemoryHourAscCreatedAtAsc(treeId, date).stream().map(MemoryResponse::from).toList(); }
  public MemoryResponse update(UserPrincipal principal, Long id, MemoryUpdateRequest request) { MemoryEntity memory = requireVisible(principal, id); requireAuthor(principal, memory); validateContent(request.content(), request.imageUrl()); memory.update(normalized(request.content()), blankToNull(request.imageUrl()), request.mood().trim(), request.date(), request.hour()); return MemoryResponse.from(memory); }
  public void delete(UserPrincipal principal, Long id) {
    MemoryEntity memory = requireVisible(principal, id); boolean author = memory.getAuthor().getId().equals(principal.id());
    boolean owner = memory.getTreeHole() != null && trees.requireMember(principal, memory.getTreeHole().getId()).getRole() == MemberRole.OWNER;
    if (!author && !owner) throw new ApiException(HttpStatus.FORBIDDEN, "只能删除自己的记忆");
    storage.delete(memory.getImageUrl()); memories.delete(memory);
  }
  private MemoryEntity requireVisible(UserPrincipal principal, Long id) { MemoryEntity memory = memories.findById(id).orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "记忆不存在")); if (memory.getTreeHole() == null && !memory.getAuthor().getId().equals(principal.id())) throw new ApiException(HttpStatus.FORBIDDEN, "无权查看该记忆"); if (memory.getTreeHole() != null) trees.requireMember(principal, memory.getTreeHole().getId()); return memory; }
  private void requireAuthor(UserPrincipal principal, MemoryEntity memory) { if (!memory.getAuthor().getId().equals(principal.id())) throw new ApiException(HttpStatus.FORBIDDEN, "只能编辑自己的记忆"); }
  private void validateContent(String content, String imageUrl) { if ((content == null || content.trim().isEmpty()) && (imageUrl == null || imageUrl.isBlank())) throw new ApiException(HttpStatus.BAD_REQUEST, "请写下一段记忆，或选择一张图片"); }
  private String normalized(String value) { return value == null ? "" : value.trim(); }
  private String blankToNull(String value) { return value == null || value.isBlank() ? null : value.trim(); }
}
