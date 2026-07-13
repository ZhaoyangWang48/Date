package com.zhiyi.server.api;

import com.zhiyi.server.api.Dtos.*;
import com.zhiyi.server.auth.UserPrincipal;
import com.zhiyi.server.service.*;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDate;
import java.util.List;

@RestController @RequestMapping("/api/tree-holes")
public class TreeHoleController {
  private final TreeHoleService trees; private final MemoryService memories;
  public TreeHoleController(TreeHoleService trees, MemoryService memories) { this.trees = trees; this.memories = memories; }
  @PostMapping @ResponseStatus(HttpStatus.CREATED) public ApiResponse<TreeHoleResponse> create(@AuthenticationPrincipal UserPrincipal principal, @Valid @RequestBody CreateTreeHoleRequest request) { return ApiResponse.ok("树洞已创建", trees.create(principal, request)); }
  @GetMapping public ApiResponse<List<TreeHoleResponse>> mine(@AuthenticationPrincipal UserPrincipal principal) { return ApiResponse.ok("success", trees.mine(principal)); }
  @PostMapping("/join") public ApiResponse<TreeHoleResponse> join(@AuthenticationPrincipal UserPrincipal principal, @Valid @RequestBody JoinTreeHoleRequest request) { return ApiResponse.ok("已加入树洞", trees.join(principal, request)); }
  @GetMapping("/{id}") public ApiResponse<TreeHoleResponse> detail(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("success", trees.detail(principal, id)); }
  @GetMapping("/{id}/members") public ApiResponse<List<TreeMemberResponse>> members(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("success", trees.members(principal, id)); }
  @DeleteMapping("/{id}/members/{userId}") public ApiResponse<Void> removeMember(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id, @PathVariable Long userId) { trees.removeMember(principal, id, userId); return ApiResponse.ok("成员已移除", null); }
  @GetMapping("/{id}/memories") public ApiResponse<List<MemoryResponse>> memories(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id) { return ApiResponse.ok("success", memories.treeMemories(principal, id)); }
  @GetMapping("/{id}/common-day") public ApiResponse<List<MemoryResponse>> commonDay(@AuthenticationPrincipal UserPrincipal principal, @PathVariable Long id, @RequestParam LocalDate date) { return ApiResponse.ok("success", memories.commonDay(principal, id, date)); }
}
