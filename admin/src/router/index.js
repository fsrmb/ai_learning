// router/index.js - 路由配置
// 配置应用路由表和全局路由守卫，实现登录状态控制

import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '../stores/user'

/**
 * 路由配置列表
 * - 公共路由：/test、/login（无需登录即可访问）
 * - 私有路由：Layout 及其子路由（需要登录才能访问）
 */
const routes = [
  {
    path: '/test',
    name: 'Test',
    component: () => import('../views/test1.vue'),
    meta: { title: '测试页面' }
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { title: '登录' }
  },
  {
    path: '/',
    name: 'Layout',
    component: () => import('../components/Layout.vue'),
    redirect: '/home',
    children: [
      {
        path: '/home',
        name: 'Home',
        component: () => import('../views/dashboard.vue'),
        meta: { title: '首页' }
      },
      {
        path: '/users',
        name: 'Users',
        component: () => import('../views/Users.vue'),
        meta: { title: '用户管理' }
      },
      {
        path: '/learning',
        name: 'Learning',
        component: () => import('../views/LearningRecord.vue'),
        meta: { title: '学习记录' }
      },
      {
        path: '/skilltree',
        name: 'SkillTree',
        component: () => import('../views/tree.vue'),
        meta: { title: '技能树' }
      }
    ]
  }
]

/**
 * 创建路由实例
 * 使用 HTML5 History 模式，去除 URL 中的 # 符号
 */
const router = createRouter({
  history: createWebHistory(),
  routes
})

/**
 * 全局路由守卫（前置守卫）
 * @description 在路由跳转前进行登录状态检查：
 *              - 访问登录页：如果已登录则重定向到首页
 *              - 访问其他页：如果未登录则重定向到登录页
 *              - 已登录时：验证 Token 是否有效，无效则登出
 */
router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore()
  const isLoginPage = to.path === '/login'
  
  if (isLoginPage) {
    if (userStore.isLoggedIn) {
      next('/home')
    } else {
      next()
    }
  } else {
    if (userStore.isLoggedIn) {
      // 已登录但用户信息为空时，验证 Token 是否有效
      if (!userStore.user) {
        try {
          // 调用获取用户信息接口验证 Token
          await userStore.fetchUserInfo()
          next()
        } catch (error) {
          // Token 无效，登出并跳转登录页
          userStore.logout()
          next('/login')
        }
      } else {
        next()
      }
    } else {
      next('/login')
    }
  }
})

export default router
