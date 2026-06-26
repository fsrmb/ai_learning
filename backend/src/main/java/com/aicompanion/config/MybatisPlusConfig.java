package com.aicompanion.config;

import com.baomidou.mybatisplus.annotation.DbType;
import com.baomidou.mybatisplus.core.handlers.MetaObjectHandler;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import lombok.extern.slf4j.Slf4j;
import org.apache.ibatis.reflection.MetaObject;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;

@Slf4j
@Configuration // auto
public class MybatisPlusConfig {

    /**
     * 分页插件
     * 不配置这个，Page 分页查询不生效
     */
    @Bean // Bean容器 Spring容器
    public MybatisPlusInterceptor mybatisPlusInterceptor() {
        MybatisPlusInterceptor interceptor = new MybatisPlusInterceptor();
        PaginationInnerInterceptor pagination = new PaginationInnerInterceptor(DbType.MYSQL);
        // 拦截器本质，Limit 0,10
        pagination.setMaxLimit(500L);  // 单页最多 500 条，防止全表查询
        interceptor.addInnerInterceptor(pagination);
        return interceptor;
    }
}