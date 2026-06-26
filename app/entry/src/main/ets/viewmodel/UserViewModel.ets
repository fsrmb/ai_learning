import { LoginRequest, LoginResponse, RegisterRequest } from '../model/User'
import { AuthApi } from '../http/AuthApi'
import { TokenUtil } from '../common/TokenUtil'

@Observed
export class UserViewModel {
  username: string = ''
  password: string = ''
  email: string = ''
  loading: boolean = false
  errorMessage: string = ''

  async login(): Promise<boolean> {
    this.loading = true
    this.errorMessage = ''

    try {
      const request: LoginRequest = {
        username: this.username,
        password: this.password
      }

      const response: LoginResponse = await AuthApi.login(request)
      await TokenUtil.setToken(response.token)
      
      const userId = response.user.id > 0 ? response.user.id : 1
      const username = response.user.username !== '' ? response.user.username : response.user.nickname
      await TokenUtil.saveUserInfo(userId, username)
      
      if (response.user.nickname) {
        await TokenUtil.saveNickname(response.user.nickname)
      }
      
      console.info(`UserViewModel: Login success - userId: ${userId}, username: ${username}, nickname: ${response.user.nickname}`)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败'
      console.error('UserViewModel: Login failed:', this.errorMessage)
      return false
    } finally {
      this.loading = false
    }
  }

  async register(): Promise<boolean> {
    this.loading = true
    this.errorMessage = ''

    try {
      const request: RegisterRequest = {
        username: this.username,
        password: this.password,
        email: this.email,
        nickname: this.username
      }

      await AuthApi.register(request)
      console.info(`UserViewModel: Register success - username: ${this.username}`)
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '注册失败'
      console.error('UserViewModel: Register failed:', this.errorMessage)
      return false
    } finally {
      this.loading = false
    }
  }

  async logout(): Promise<void> {
    await TokenUtil.clearAll()
    this.username = ''
    this.password = ''
    this.email = ''
  }

  async isLoggedIn(): Promise<boolean> {
    return TokenUtil.hasToken()
  }

  async getStoredUsername(): Promise<string> {
    return TokenUtil.getUsername()
  }

  clearError(): void {
    this.errorMessage = ''
  }
}