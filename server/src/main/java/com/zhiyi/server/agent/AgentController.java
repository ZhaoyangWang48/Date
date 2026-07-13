package com.zhiyi.server.agent;

import com.zhiyi.server.api.ApiResponse;
import com.zhiyi.server.api.Dtos;
import com.zhiyi.server.auth.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/agent")
public class AgentController {

    private final RemembererService remembererService;

    public AgentController(RemembererService remembererService) {
        this.remembererService = remembererService;
    }

    @PostMapping("/rememberer/chat")
    public ApiResponse<Dtos.AgentChatResponse> chat(
            @AuthenticationPrincipal UserPrincipal principal,
            @Valid @RequestBody Dtos.AgentChatRequest request) {
        Dtos.AgentChatResponse resp = remembererService.chat(principal, request.treeHoleId(), request.question());
        return ApiResponse.ok("ok", resp);
    }
}
