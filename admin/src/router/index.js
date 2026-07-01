import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '../stores/user'

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
    path: '/register',
    name: 'Register',
    component: () => import('../views/Register.vue'),
    meta: { title: '注册' }
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
        component: () => import('../views/SkillTree.vue'),
        meta: { title: '技能树' }
      },
      {
        path: '/ai-management',
        name: 'AiManagement',
        component: () => import('../views/AiManagement.vue'),
        meta: { title: 'AI管理' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to, from, next) => {
  const userStore = useUserStore()
  const isAuthPage = to.path === '/login' || to.path === '/register'
  
  if (isAuthPage) {
    if (userStore.isLoggedIn && userStore.user) {
      next('/home')
    } else {
      next()
    }
  } else {
    if (userStore.isLoggedIn) {
      if (!userStore.user) {
        try {
          await userStore.fetchUserInfo()
          next()
        } catch (error) {
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
