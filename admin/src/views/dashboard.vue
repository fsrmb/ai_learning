<template>
  <div class="dashboard">
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

    <el-row :gutter="20" class="chart-row">
      <el-col :span="24">
        <el-card shadow="hover">
          <template #header>近30天用户增长趋势</template>
          <div ref="lineChartRef" class="chart-container"></div>
        </el-card>
      </el-col>
    </el-row>

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
import { getDashboardData } from '@/api/dashboard'

const barChartRef = ref(null)
const pieChartRef = ref(null)
const lineChartRef = ref(null)
let barChartInstance = null
let pieChartInstance = null
let lineChartInstance = null

const data = ref(null)

async function fetchData() {
  try {
    data.value = await getDashboardData()
    initBarChart()
    initPieChart()
    initLineChart()
  } catch (error) {
    console.error('获取看板数据失败:', error)
    data.value = {
      totalUsers: '-',
      totalSkills: '-',
      totalRecords: '-',
      aiCalls: '-',
      dailyAiCalls: [],
      skillDistribution: [],
      dailyNewUsers: [],
      recentActivities: []
    }
  }
}

function initBarChart() {
  if (!barChartRef.value || !data.value?.dailyAiCalls) return

  barChartInstance = echarts.init(barChartRef.value)

  const dates = data.value.dailyAiCalls.map(item => item.date)
  const calls = data.value.dailyAiCalls.map(item => item.count)

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
  if (!pieChartRef.value || !data.value?.skillDistribution) return

  pieChartInstance = echarts.init(pieChartRef.value)

  const pieData = data.value.skillDistribution.map(item => ({
    name: item.name,
    value: item.count
  }))

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
        data: pieData
      }
    ]
  }

  pieChartInstance.setOption(option)
}

function initLineChart() {
  if (!lineChartRef.value || !data.value?.dailyNewUsers) return

  lineChartInstance = echarts.init(lineChartRef.value)

  const dates = data.value.dailyNewUsers.map(item => item.date)
  const newUsers = data.value.dailyNewUsers.map(item => item.count)

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
  fetchData()
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