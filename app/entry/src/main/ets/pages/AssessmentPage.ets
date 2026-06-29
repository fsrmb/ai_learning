import { router } from '@kit.ArkUI'
import { NavBar } from '../components/NavBar'
import { AssessmentApi } from '../http/AssessmentApi'
import {
  DifficultyOption,
  StartAssessmentRequest,
  StartAssessmentResponse,
  AssessmentQuestion,
  SubmitAnswerRequest,
  AnswerItem,
  AssessmentResult,
  AnswerDetail
} from '../model/Assessment'

class AssessmentPageParams {
  nodeId: number = 0
  nodeName: string = ''
}

// 页面状态枚举
type PageState = 'SELECT_DIFFICULTY' | 'ANSWERING' | 'RESULT'

@Entry
@Component
struct AssessmentPage {
  @State nodeId: number = 0
  @State nodeName: string = ''
  @State difficultyOptions: DifficultyOption[] = []
  @State selectedDifficulty: number = 0
  @State expandedDifficulty: number = 0
  
  @State pageState: PageState = 'SELECT_DIFFICULTY'
  @State isLoading: boolean = false
  
  // 答题相关
  @State assessmentId: number = 0
  @State questions: AssessmentQuestion[] = []
  @State currentQuestionIndex: number = 0
  @State userAnswers: Map<number, string> = new Map()
  @State startTime: number = 0
  
  // 结果相关
  @State result: AssessmentResult = new AssessmentResult()
  
  aboutToAppear(): void {
    const params: AssessmentPageParams = router.getParams() as AssessmentPageParams
    if (params) {
      this.nodeId = params.nodeId
      this.nodeName = params.nodeName
      this.loadDifficultyOptions()
    }
  }
  
  private async loadDifficultyOptions(): Promise<void> {
    this.isLoading = true
    try {
      this.difficultyOptions = await AssessmentApi.getDifficultyOptions(this.nodeId)
    } catch (error) {
      console.error('Failed to load difficulty options:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  private async startAssessment(difficulty: number): Promise<void> {
    this.isLoading = true
    try {
      const request: StartAssessmentRequest = {
        nodeId: this.nodeId,
        difficulty: difficulty
      }
      const response: StartAssessmentResponse = await AssessmentApi.startAssessment(request)
      this.assessmentId = response.assessmentId
      this.questions = response.questions
      this.currentQuestionIndex = 0
      this.userAnswers = new Map()
      this.startTime = Date.now()
      this.pageState = 'ANSWERING'
    } catch (error) {
      console.error('Failed to start assessment:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  private selectAnswer(answer: string): void {
    const questionId = this.questions[this.currentQuestionIndex].questionId
    this.userAnswers.set(questionId, answer)
  }
  
  private nextQuestion(): void {
    if (this.currentQuestionIndex < this.questions.length - 1) {
      this.currentQuestionIndex++
    } else {
      this.submitAnswers()
    }
  }
  
  private prevQuestion(): void {
    if (this.currentQuestionIndex > 0) {
      this.currentQuestionIndex--
    }
  }
  
  private async submitAnswers(): Promise<void> {
    this.isLoading = true
    try {
      const answers: AnswerItem[] = []
      this.userAnswers.forEach((answer: string, questionId: number) => {
        answers.push({
          questionId: questionId,
          answer: answer,
          timeSpent: 0
        })
      })
      
      const totalTime = Math.floor((Date.now() - this.startTime) / 1000)
      const request: SubmitAnswerRequest = {
        answers: answers,
        totalTime: totalTime
      }
      
      this.result = await AssessmentApi.submitAnswer(this.assessmentId, request)
      this.pageState = 'RESULT'
    } catch (error) {
      console.error('Failed to submit answers:', error)
    } finally {
      this.isLoading = false
    }
  }
  
  private toggleDifficultyExpand(level: number): void {
    if (this.expandedDifficulty === level) {
      this.expandedDifficulty = 0
    } else {
      this.expandedDifficulty = level
    }
  }
  
  build() {
    Column() {
      NavBar({ title: this.nodeName + ' - 技能评估', showBack: true })
      
      Column() {
        if (this.isLoading) {
          Column() {
            Text('加载中...')
              .fontSize(16)
              .fontColor('#8898aa')
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
        } else if (this.pageState === 'SELECT_DIFFICULTY') {
          this.buildDifficultySelection()
        } else if (this.pageState === 'ANSWERING') {
          this.buildAnswering()
        } else if (this.pageState === 'RESULT') {
          this.buildResult()
        }
      }
      .width('90%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f7fa')
  }
  
  // 难度选择界面
  @Builder
  buildDifficultySelection() {
    Column({ space: 16 }) {
      Text('选择难度级别')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1a1a2e')
        .margin({ top: 16 })
      
      Text('难度越高，奖励越多。难度1通过可获得20exp，难度5通过可获得100exp。')
        .fontSize(14)
        .fontColor('#8898aa')
        .margin({ bottom: 16 })
      
      List({ space: 8 }) {
        ForEach(this.difficultyOptions, (option: DifficultyOption) => {
          ListItem() {
            Column() {
              Row() {
                Text(`难度 ${option.level}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#1a1a2e')
                
                Blank()
                
                if (option.passed) {
                  Text('已通过 ✓')
                    .fontSize(14)
                    .fontColor('#4caf50')
                }
                
                Text(option.exp + ' exp')
                  .fontSize(14)
                  .fontColor('#667eea')
                  .margin({ left: 8 })
                
                Text(this.expandedDifficulty === option.level ? '▼' : '▶')
                  .fontSize(12)
                  .fontColor('#8898aa')
                  .margin({ left: 8 })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#ffffff')
              .borderRadius(12)
              .onClick(() => {
                this.toggleDifficultyExpand(option.level)
              })
              
              if (this.expandedDifficulty === option.level) {
                Column({ space: 12 }) {
                  Text(option.description)
                    .fontSize(14)
                    .fontColor('#666666')
                    .width('100%')
                    .padding({ left: 16, right: 16, top: 8 })
                  
                  Row({ space: 12 }) {
                    ForEach(['A', 'B', 'C', 'D'], (letter: string) => {
                      Row() {
                        Text(letter)
                          .fontSize(12)
                          .fontColor('#ffffff')
                      }
                      .width(24)
                      .height(24)
                      .borderRadius(12)
                      .backgroundColor(option.color)
                      .justifyContent(FlexAlign.Center)
                    }, (letter: string) => letter)
                  }
                  .width('100%')
                  .justifyContent(FlexAlign.Center)
                  .margin({ top: 8 })
                  
                  Button('开始答题')
                    .fontSize(16)
                    .fontColor('#ffffff')
                    .backgroundColor(option.color)
                    .borderRadius(24)
                    .width('80%')
                    .height(48)
                    .margin({ top: 16, bottom: 8 })
                    .onClick(() => {
                      this.selectedDifficulty = option.level
                      this.startAssessment(option.level)
                    })
                }
                .width('100%')
                .backgroundColor('#f9f9f9')
                .borderRadius(12)
                .margin({ top: 4 })
              }
            }
            .width('100%')
          }
        }, (option: DifficultyOption) => option.level.toString())
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  // 答题界面
  @Builder
  buildAnswering() {
    Column({ space: 16 }) {
      Row() {
        Text(`题目 ${this.currentQuestionIndex + 1} / ${this.questions.length}`)
          .fontSize(16)
          .fontColor('#1a1a2e')
        
        Blank()
        
        Text(`难度 ${this.selectedDifficulty}`)
          .fontSize(14)
          .fontColor('#667eea')
      }
      .width('100%')
      .margin({ top: 16 })
      
      if (this.questions.length > 0) {
        Column() {
          Text(this.questions[this.currentQuestionIndex].questionText)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
            .width('100%')
            .margin({ bottom: 24 })
          
          Column({ space: 12 }) {
            ForEach(this.questions[this.currentQuestionIndex].options, (option: string) => {
              Row() {
                Text(option)
                  .fontSize(16)
                  .fontColor('#1a1a2e')
              }
              .width('100%')
              .padding(16)
              .backgroundColor(
                this.userAnswers.get(this.questions[this.currentQuestionIndex].questionId) === option.charAt(0)
                  ? '#667eea'
                  : '#ffffff'
              )
              .borderRadius(12)
              .onClick(() => {
                this.selectAnswer(option.charAt(0))
              })
            }, (option: string) => option)
          }
          .width('100%')
        }
        .width('100%')
        .padding(24)
        .backgroundColor('#ffffff')
        .borderRadius(16)
      }
      
      Row({ space: 16 }) {
        if (this.currentQuestionIndex > 0) {
          Button('上一题')
            .fontSize(16)
            .fontColor('#667eea')
            .backgroundColor('#ffffff')
            .borderRadius(24)
            .width('40%')
            .height(48)
            .onClick(() => {
              this.prevQuestion()
            })
        }
        
        Button(this.currentQuestionIndex < this.questions.length - 1 ? '下一题' : '提交')
          .fontSize(16)
          .fontColor('#ffffff')
          .backgroundColor('#667eea')
          .borderRadius(24)
          .width(this.currentQuestionIndex > 0 ? '40%' : '80%')
          .height(48)
          .onClick(() => {
            this.nextQuestion()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
  }
  
  // 结果界面
  @Builder
  buildResult() {
    Column({ space: 16 }) {
      Column() {
        Text(this.result.passed ? '🎉 通过' : '❌ 未通过')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.result.passed ? '#4caf50' : '#f44336')
        
        Text(`得分: ${this.result.score}%`)
          .fontSize(24)
          .fontColor('#1a1a2e')
          .margin({ top: 8 })
        
        Text(`正确 ${this.result.correctCount} 题，错误 ${this.result.wrongCount} 题`)
          .fontSize(14)
          .fontColor('#8898aa')
          .margin({ top: 8 })
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#ffffff')
      .borderRadius(16)
      .margin({ top: 16 })
      
      if (this.result.expIncreased) {
        Column() {
          Text('经验值提升')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1a1a2e')
          
          Row() {
            Text(`${this.result.previousExp} exp`)
              .fontSize(14)
              .fontColor('#8898aa')
            
            Text(' → ')
              .fontSize(14)
              .fontColor('#8898aa')
            
            Text(`${this.result.newExp} exp`)
              .fontSize(18)
              .fontColor('#667eea')
              .fontWeight(FontWeight.Bold)
          }
          .margin({ top: 8 })
          
          if (this.result.nodeCompleted) {
            Text('🎊 技能节点已完成!')
              .fontSize(16)
              .fontColor('#4caf50')
              .margin({ top: 8 })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#e8f5e9')
        .borderRadius(12)
        .margin({ top: 8 })
      }
      
      Text('答题详情')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1a1a2e')
        .margin({ top: 16 })
      
      List({ space: 8 }) {
        ForEach(this.result.details, (detail: AnswerDetail) => {
          ListItem() {
            Column() {
              Row() {
                Text(detail.isCorrect ? '✓' : '✗')
                  .fontSize(16)
                  .fontColor(detail.isCorrect ? '#4caf50' : '#f44336')
                  .margin({ right: 12 })
                
                Text(`Q${detail.questionId}`)
                  .fontSize(14)
                  .fontColor('#1a1a2e')
                
                Blank()
                
                Text(`你的答案: ${detail.userAnswer}`)
                  .fontSize(14)
                  .fontColor(detail.isCorrect ? '#4caf50' : '#f44336')
              }
              .width('100%')
              
              if (!detail.isCorrect) {
                Text(`正确答案: ${detail.correctAnswer}`)
                  .fontSize(12)
                  .fontColor('#8898aa')
                  .margin({ top: 8 })
                
                Text(detail.explanation)
                  .fontSize(12)
                  .fontColor('#666666')
                  .margin({ top: 4 })
                  .width('100%')
              }
            }
            .width('100%')
            .padding(12)
            .backgroundColor('#ffffff')
            .borderRadius(12)
          }
        }, (detail: AnswerDetail) => detail.questionId.toString())
      }
      .width('100%')
      .layoutWeight(1)
      
      Button('返回技能节点')
        .fontSize(16)
        .fontColor('#ffffff')
        .backgroundColor('#667eea')
        .borderRadius(24)
        .width('80%')
        .height(48)
        .margin({ top: 16 })
        .onClick(() => {
          router.back()
        })
    }
    .width('100%')
    .layoutWeight(1)
  }
}