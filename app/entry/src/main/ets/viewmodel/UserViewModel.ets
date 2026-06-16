import { LoginRequest, LoginResponse } from '../model/User'
import { AuthApi } from '../http/AuthApi'
import { TokenUtil } from '../common/TokenUtil'

@Observed
export class UserViewModel {
  username: string = ''
  password: string = ''
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
      return true
    } catch (error) {
      this.errorMessage = error instanceof Error ? error.message : '登录失败'
      return false
    } finally {
      this.loading = false
    }
  }

  async logout(): Promise<void> {
    await TokenUtil.removeToken()
    this.username = ''
    this.password = ''
  }

  async isLoggedIn(): Promise<boolean> {
    return TokenUtil.hasToken()
  }

  clearError(): void {
    this.errorMessage = ''
  }
}
