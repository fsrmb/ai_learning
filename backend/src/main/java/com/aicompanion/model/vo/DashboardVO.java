package com.aicompanion.model.vo;

import lombok.Data;

import java.util.List;

@Data
public class DashboardVO {

    private Long totalUsers;

    private Long totalSkills;

    private Long totalRecords;

    private Long aiCalls;

    private List<DailyStat> dailyAiCalls;

    private List<SkillDistribution> skillDistribution;

    private List<DailyStat> dailyNewUsers;

    private List<RecentActivity> recentActivities;

    @Data
    public static class DailyStat {
        private String date;
        private Long count;
    }

    @Data
    public static class SkillDistribution {
        private String name;
        private Long count;
    }

    @Data
    public static class RecentActivity {
        private String content;
        private String time;
    }
}