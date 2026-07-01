package com.aicompanion.service.impl;

import com.aicompanion.mapper.*;
import com.aicompanion.model.entity.*;
import com.aicompanion.model.vo.DashboardVO;
import com.aicompanion.model.vo.PageResult;
import com.aicompanion.model.vo.UserAiStatsVO;
import com.aicompanion.service.DashboardService;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class DashboardServiceImpl implements DashboardService {

    private final UserMapper userMapper;
    private final SkillTreeMapper skillTreeMapper;
    private final SkillNodeMapper skillNodeMapper;
    private final LearningRecordMapper learningRecordMapper;
    private final AiChatHistoryMapper aiChatHistoryMapper;
    private final ChatMessageMapper chatMessageMapper;
    private final ChatConversationMapper chatConversationMapper;

    @Override
    public DashboardVO getDashboardData() {
        DashboardVO vo = new DashboardVO();

        vo.setTotalUsers(userMapper.selectCount(new LambdaQueryWrapper<User>().eq(User::getStatus, 1)));
        vo.setTotalSkills(skillTreeMapper.selectCount(new LambdaQueryWrapper<SkillTree>().eq(SkillTree::getStatus, 1)));
        vo.setTotalRecords(learningRecordMapper.selectCount(new LambdaQueryWrapper<LearningRecord>().eq(LearningRecord::getDeleted, 0)));

        Long aiCallCount = chatMessageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                .eq(ChatMessage::getRole, "ASSISTANT")
                .eq(ChatMessage::getDeleted, 0));
        vo.setAiCalls(aiCallCount);

        vo.setDailyAiCalls(getDailyAiCalls(7));
        vo.setSkillDistribution(getSkillDistribution());
        vo.setDailyNewUsers(getDailyNewUsers(30));
        vo.setRecentActivities(getRecentActivities());

        return vo;
    }

    @Override
    public List<UserAiStatsVO> getUserAiStats() {
        List<User> users = userMapper.selectList(new LambdaQueryWrapper<User>().eq(User::getStatus, 1));

        return users.stream().map(user -> {
            UserAiStatsVO stats = new UserAiStatsVO();
            stats.setUserId(user.getId());
            stats.setUsername(user.getUsername());
            stats.setNickname(user.getNickname());

            Long chatCount = chatMessageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getRole, "ASSISTANT")
                    .inSql(ChatMessage::getConversationId,
                            "SELECT id FROM chat_conversation WHERE user_id = " + user.getId())
                    .eq(ChatMessage::getDeleted, 0));
            stats.setChatCount(chatCount);

            List<AIChatHistory> histories = aiChatHistoryMapper.selectList(
                    new LambdaQueryWrapper<AIChatHistory>().eq(AIChatHistory::getUserId, user.getId()));
            stats.setTotalTokens(histories.stream().mapToLong(h -> h.getTokenCount() != null ? h.getTokenCount() : 0).sum());
            stats.setTotalDurationMs(histories.stream().mapToLong(h -> h.getDurationMs() != null ? h.getDurationMs() : 0).sum());

            return stats;
        }).sorted((a, b) -> Long.compare(a.getUserId(), b.getUserId()))
                .collect(Collectors.toList());
    }

    @Override
    public PageResult<UserAiStatsVO> getUserAiStats(Integer page, Integer size) {
        LambdaQueryWrapper<User> userQueryWrapper = new LambdaQueryWrapper<User>()
                .eq(User::getStatus, 1);
        
        Long total = userMapper.selectCount(userQueryWrapper);
        
        int start = (page - 1) * size;
        List<User> users = userMapper.selectList(userQueryWrapper.last("LIMIT " + start + ", " + size));

        List<UserAiStatsVO> statsList = users.stream().map(user -> {
            UserAiStatsVO stats = new UserAiStatsVO();
            stats.setUserId(user.getId());
            stats.setUsername(user.getUsername());
            stats.setNickname(user.getNickname());

            Long chatCount = chatMessageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getRole, "ASSISTANT")
                    .inSql(ChatMessage::getConversationId,
                            "SELECT id FROM chat_conversation WHERE user_id = " + user.getId())
                    .eq(ChatMessage::getDeleted, 0));
            stats.setChatCount(chatCount);

            List<AIChatHistory> histories = aiChatHistoryMapper.selectList(
                    new LambdaQueryWrapper<AIChatHistory>().eq(AIChatHistory::getUserId, user.getId()));
            stats.setTotalTokens(histories.stream().mapToLong(h -> h.getTokenCount() != null ? h.getTokenCount() : 0).sum());
            stats.setTotalDurationMs(histories.stream().mapToLong(h -> h.getDurationMs() != null ? h.getDurationMs() : 0).sum());

            return stats;
        }).sorted((a, b) -> Long.compare(a.getUserId(), b.getUserId()))
                .collect(Collectors.toList());

        return PageResult.of(statsList, total, page, size);
    }

    private List<DashboardVO.DailyStat> getDailyAiCalls(int days) {
        List<DashboardVO.DailyStat> result = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            LocalDateTime start = date.atStartOfDay();
            LocalDateTime end = date.plusDays(1).atStartOfDay();

            Long count = chatMessageMapper.selectCount(new LambdaQueryWrapper<ChatMessage>()
                    .eq(ChatMessage::getRole, "ASSISTANT")
                    .ge(ChatMessage::getUpdateTime, start)
                    .lt(ChatMessage::getUpdateTime, end)
                    .eq(ChatMessage::getDeleted, 0));

            DashboardVO.DailyStat stat = new DashboardVO.DailyStat();
            stat.setDate(date.format(formatter));
            stat.setCount(count);
            result.add(stat);
        }

        return result;
    }

    private List<DashboardVO.DailyStat> getDailyNewUsers(int days) {
        List<DashboardVO.DailyStat> result = new ArrayList<>();
        DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MM-dd");

        for (int i = days - 1; i >= 0; i--) {
            LocalDate date = LocalDate.now().minusDays(i);
            LocalDateTime start = date.atStartOfDay();
            LocalDateTime end = date.plusDays(1).atStartOfDay();

            Long count = userMapper.selectCount(new LambdaQueryWrapper<User>()
                    .ge(User::getCreateTime, start)
                    .lt(User::getCreateTime, end));

            DashboardVO.DailyStat stat = new DashboardVO.DailyStat();
            stat.setDate(date.format(formatter));
            stat.setCount(count);
            result.add(stat);
        }

        return result;
    }

    private List<DashboardVO.SkillDistribution> getSkillDistribution() {
        List<SkillTree> trees = skillTreeMapper.selectList(new LambdaQueryWrapper<SkillTree>().eq(SkillTree::getStatus, 1));

        Map<String, Long> categoryCount = trees.stream()
                .collect(Collectors.groupingBy(SkillTree::getCategory, Collectors.counting()));

        List<DashboardVO.SkillDistribution> result = new ArrayList<>();
        Map<String, String> categoryLabels = Map.of(
                "FRONTEND", "前端开发",
                "BACKEND", "后端开发",
                "DATABASE", "数据库",
                "ALGORITHM", "算法",
                "MOBILE", "移动端",
                "DEVOPS", "运维",
                "SOFT_SKILLS", "软技能"
        );

        categoryCount.forEach((category, count) -> {
            DashboardVO.SkillDistribution dist = new DashboardVO.SkillDistribution();
            dist.setName(categoryLabels.getOrDefault(category, category));
            dist.setCount(count);
            result.add(dist);
        });

        return result;
    }

    private List<DashboardVO.RecentActivity> getRecentActivities() {
        List<DashboardVO.RecentActivity> activities = new ArrayList<>();

        List<LearningRecord> records = learningRecordMapper.selectList(new LambdaQueryWrapper<LearningRecord>()
                .eq(LearningRecord::getDeleted, 0)
                .orderByDesc(LearningRecord::getCreateTime)
                .last("LIMIT 3"));

        for (LearningRecord record : records) {
            DashboardVO.RecentActivity activity = new DashboardVO.RecentActivity();
            activity.setContent("用户 " + record.getUserName() + " 完成了学习：" + record.getCourseName());
            activity.setTime(record.getCreateTime().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
            activities.add(activity);
        }

        List<ChatConversation> conversations = chatConversationMapper.selectList(new LambdaQueryWrapper<ChatConversation>()
                .eq(ChatConversation::getStatus, 1)
                .orderByDesc(ChatConversation::getUpdateTime)
                .last("LIMIT 2"));

        for (ChatConversation conv : conversations) {
            User user = userMapper.selectById(conv.getUserId());
            if (user != null) {
                DashboardVO.RecentActivity activity = new DashboardVO.RecentActivity();
                activity.setContent("用户 " + user.getNickname() + " 发起了AI对话");
                activity.setTime(conv.getUpdateTime().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm")));
                activities.add(activity);
            }
        }

        activities.sort((a, b) -> b.getTime().compareTo(a.getTime()));
        return activities.stream().limit(5).collect(Collectors.toList());
    }
}