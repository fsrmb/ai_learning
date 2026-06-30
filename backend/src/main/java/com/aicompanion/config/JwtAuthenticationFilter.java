package com.aicompanion.config;

import com.aicompanion.common.util.JwtUtil;
import com.aicompanion.model.entity.User;
import com.aicompanion.mapper.UserMapper;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

@Slf4j
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtUtil jwtUtil;
    private final UserMapper userMapper;
    private final AntPathMatcher pathMatcher = new AntPathMatcher();

    // 白名单：这些路径不需要认证
    private static final String[] WHITE_LIST = {
            "/api/auth/**",
            "/api/chat/stream",
            "/api/chat/stream/test",
            "/doc.html", "/webjars/**", "/v3/api-docs/**",
            "/swagger-ui/**", "/swagger-resources/**",
            "/actuator/**"
    };

    @Override
    protected void doFilterInternal(@NonNull HttpServletRequest request,
                                    @NonNull HttpServletResponse response,
                                    @NonNull FilterChain filterChain)
            throws ServletException, IOException {

        String requestPath = request.getRequestURI();

        // ① 白名单路径直接放行
        if (isWhiteListed(requestPath)) {
            filterChain.doFilter(request, response);
            return;
        }

        // ② 提取 Token
        String token = extractToken(request);

        if (StringUtils.hasText(token)) {
            try {
                if (jwtUtil.validateToken(token)) {
                    // ③ Token 有效，解析用户信息
                    Long userId = jwtUtil.getUserIdFromToken(token);
                    String username = jwtUtil.getUsername(token);

                    // ④ 查询用户角色，构建权限列表
                    User user = userMapper.selectById(userId);
                    List<SimpleGrantedAuthority> authorities = new ArrayList<>();
                    authorities.add(new SimpleGrantedAuthority("ROLE_USER"));
                    if (user != null && "ADMIN".equals(user.getRole())) {
                        authorities.add(new SimpleGrantedAuthority("ROLE_ADMIN"));
                    }

                    // ⑤ 构建 UserDetails，放入 SecurityContext
                    UserDetails userDetails = org.springframework.security.core.userdetails.User.builder()
                            .username(userId.toString())
                            .password("")
                            .authorities(authorities)
                            .build();

                    UsernamePasswordAuthenticationToken authentication =
                            new UsernamePasswordAuthenticationToken(
                                    userDetails, null, userDetails.getAuthorities());
                    authentication.setDetails(
                            new WebAuthenticationDetailsSource().buildDetails(request));

                    SecurityContextHolder.getContext().setAuthentication(authentication);
                    log.debug("JWT认证成功: userId={}, username={}", userId, username);
                }
            } catch (Exception e) {
                log.warn("JWT认证失败: {}", e.getMessage());
            }
        }

        // ⑥ 继续执行后续过滤器
        filterChain.doFilter(request, response);
    }

    /** 从 Authorization 头提取 Bearer Token */
    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return null;
    }

    /** 检查路径是否在白名单中 */
    private boolean isWhiteListed(String path) {
        for (String pattern : WHITE_LIST) {
            if (pathMatcher.match(pattern, path)) {
                return true;
            }
        }
        return false;
    }
}