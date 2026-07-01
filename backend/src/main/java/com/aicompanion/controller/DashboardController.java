package com.aicompanion.controller;

import com.aicompanion.common.response.Result;
import com.aicompanion.model.vo.DashboardVO;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserAiStatsVO;
import com.aicompanion.service.DashboardService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "数据看板", description = "首页数据统计接口")
@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
public class DashboardController {

    private final DashboardService dashboardService;

    @Operation(summary = "获取看板数据", description = "获取首页统计数据")
    @GetMapping
    public Result<DashboardVO> getDashboard() {
        DashboardVO data = dashboardService.getDashboardData();
        return Result.success(data);
    }

    @Operation(summary = "获取用户AI调用统计", description = "获取每个用户的AI调用次数统计")
    @GetMapping("/user-ai-stats")
    public Result<PageResult<UserAiStatsVO>> getUserAiStats(
            @RequestParam(defaultValue = "1") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {
        PageResult<UserAiStatsVO> pageResult = dashboardService.getUserAiStats(page, size);
        return Result.success(pageResult);
    }
}