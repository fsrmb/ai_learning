<!-- views/dashboard/index.vue -->
<template>
  <div class="dashboard">
    <!-- 第一行：统计卡片 -->
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>用户总数</template>
          <div class="stat-value">{{ data?.totalUsers ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>技能数量</template>
          <div class="stat-value">{{ data?.totalSkills ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>学习记录</template>
          <div class="stat-value">{{ data?.totalRecords ?? '-' }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <template #header>AI调用次数</template>
          <div class="stat-value">{{ data?.aiCalls ?? '-' }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第二行：柱状图 + 饼图 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="16">
        <el-card shadow="hover">
          <template #header>近7天AI调用次数</template>
          <div ref="barChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <template #header>技能分布</template>
          <div ref="pieChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第三行：折线图 -->
    <el-row :gutter="20" class="chart-row">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>近30天用户增长趋势</template>
          <div ref="lineChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 第四行：活动列表 -->
    <el-row :gutter="20" class="activity-row">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>最近活动</template>
          <el-table :data="data?.recentActivities ?? []" stripe>
            <el-table-column prop="content" label="内容" />
            <el-table-column prop="time" label="时间" width="180" />
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import * as echarts from 'echarts'

const barChartRef = ref(null)
const pieChartRef = ref(null)
const lineChartRef = ref(null)
let barChartInstance = null
let pieChartInstance = null
let lineChartInstance = null

const data = ref({
  totalUsers: 128,
  totalSkills: 24,
  totalRecords: 856,
  aiCalls: 1234,
  recentActivities: [
    { content: '用户 admin 完成了技能评估', time: '2024-01-15 10:30' },
    { content: '用户 user1 开始了新的学习任务', time: '2024-01-15 09:15' },
    { content: '用户 user2 完成了模拟面试', time: '2024-01-14 16:45' },
    { content: '用户 user3 调用了AI助手', time: '2024-01-14 14:20' },
    { content: '用户 user4 注册了新账户', time: '2024-01-13 11:00' }
  ]
})

function initBarChart() {
  if (!barChartRef.value) return

  barChartInstance = echarts.init(barChartRef.value)

  const today = new Date()
  const dates = []
  const calls = []

  for (let i = 6; i >= 0; i--) {
    const date = new Date(today)
    date.setDate(date.getDate() - i)
    const month = date.getMonth() + 1
    const day = date.getDate()
    dates.push(`${month}月${day}日`)
    calls.push(Math.floor(Math.random() * 200) + 50)
  }

  const option = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      data: dates,
      axisLabel: {
        interval: 0,
        rotate: 30
      }
    },
    yAxis: {
      type: 'value',
      name: '调用次数'
    },
    series: [
      {
        name: 'AI调用次数',
        type: 'bar',
        data: calls,
        itemStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: '#6366f1' },
            { offset: 1, color: '#8b5cf6' }
          ]),
          borderRadius: [4, 4, 0, 0]
        },
        emphasis: {
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
              { offset: 0, color: '#818cf8' },
              { offset: 1, color: '#a78bfa' }
            ])
          }
        }
      }
    ]
  }

  barChartInstance.setOption(option)
}

function initPieChart() {
  if (!pieChartRef.value) return

  pieChartInstance = echarts.init(pieChartRef.value)

  const option = {
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c} ({d}%)'
    },
    legend: {
      orient: 'vertical',
      left: 'left',
      top: 'center'
    },
    series: [
      {
        name: '技能分布',
        type: 'pie',
        radius: ['40%', '70%'],
        center: ['55%', '50%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 8,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 14,
            fontWeight: 'bold'
          }
        },
        labelLine: {
          show: false
        },
        data: [
          { value: 35, name: '前端开发' },
          { value: 25, name: '后端开发' },
          { value: 20, name: '数据科学' },
          { value: 15, name: '人工智能' },
          { value: 5, name: '其他' }
        ]
      }
    ]
  }

  pieChartInstance.setOption(option)
}

function initLineChart() {
  if (!lineChartRef.value) return

  lineChartInstance = echarts.init(lineChartRef.value)

  const today = new Date()
  const dates = []
  const newUsers = []

  for (let i = 29; i >= 0; i--) {
    const date = new Date(today)
    date.setDate(date.getDate() - i)
    const month = date.getMonth() + 1
    const day = date.getDate()
    dates.push(`${month}-${day}`)
    newUsers.push(Math.floor(Math.random() * 50) + 10)
  }

  const option = {
    tooltip: {
      trigger: 'axis',
      backgroundColor: 'rgba(255, 255, 255, 0.95)',
      borderColor: '#e5e7eb',
      borderWidth: 1,
      textStyle: {
        color: '#374151'
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      top: '10%',
      containLabel: true
    },
    xAxis: {
      type: 'category',
      boundaryGap: false,
      data: dates,
      axisLine: {
        lineStyle: {
          color: '#e5e7eb'
        }
      },
      axisLabel: {
        color: '#9ca3af',
        interval: 4
      }
    },
    yAxis: {
      type: 'value',
      name: '新增用户数',
      axisLine: {
        show: false
      },
      axisTick: {
        show: false
      },
      splitLine: {
        lineStyle: {
          color: '#f3f4f6',
          type: 'dashed'
        }
      },
      axisLabel: {
        color: '#9ca3af'
      }
    },
    series: [
      {
        name: '新增用户',
        type: 'line',
        smooth: true,
        data: newUsers,
        lineStyle: {
          width: 3,
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: '#10b981' },
            { offset: 1, color: '#34d399' }
          ])
        },
        areaStyle: {
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: 'rgba(16, 185, 129, 0.3)' },
            { offset: 1, color: 'rgba(16, 185, 129, 0.05)' }
          ])
        },
        itemStyle: {
          color: '#10b981'
        },
        symbol: 'circle',
        symbolSize: 6,
        emphasis: {
          itemStyle: {
            color: '#10b981',
            borderColor: '#fff',
            borderWidth: 3,
            shadowBlur: 10,
            shadowColor: 'rgba(16, 185, 129, 0.5)'
          }
        }
      }
    ]
  }

  lineChartInstance.setOption(option)
}

function handleResize() {
  barChartInstance?.resize()
  pieChartInstance?.resize()
  lineChartInstance?.resize()
}

onMounted(() => {
  initBarChart()
  initPieChart()
  initLineChart()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  barChartInstance?.dispose()
  pieChartInstance?.dispose()
  lineChartInstance?.dispose()
})
</script>

<style scoped>
.dashboard {
  padding: 20px;
}

.stat-cards {
  margin-bottom: 20px;
}

.stat-value {
  font-size: 32px;
  font-weight: bold;
  color: #6366f1;
  text-align: center;
  margin-top: 10px;
}

.chart-row {
  margin-bottom: 20px;
}

.chart-container {
  height: 350px;
}

.activity-row {
  margin-bottom: 20px;
}
</style>