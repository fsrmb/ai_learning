package com.aicompanion.service;

import com.aicompanion.model.vo.DashboardVO;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserAiStatsVO;

import java.util.List;

public interface DashboardService {

    DashboardVO getDashboardData();

    List<UserAiStatsVO> getUserAiStats();

    PageResult<UserAiStatsVO> getUserAiStats(Integer page, Integer size);
}