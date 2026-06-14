package com.aicompanion;

import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * AI Companion 应用启动类
 */
@SpringBootApplication
@MapperScan("com.aicompanion.mapper")
public class AiCompanionApplication {
    
    public static void main(String[] args) {
        SpringApplication.run(AiCompanionApplication.class, args);
    }
}
