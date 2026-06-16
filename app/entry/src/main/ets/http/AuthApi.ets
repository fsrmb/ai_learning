import { HttpClient } from './HttpClient'
import { LoginRequest, LoginResponse, RegisterRequest } from '../model/User'

export class AuthApi {
  // 登录
  static async login(data: LoginRequest): Promise<LoginResponse> {
    return HttpClient.post<LoginResponse>('/api/auth/login', data)
  }

  // 注册
  static async register(data: RegisterRequest): Promise<void> {
    return HttpClient.post<void>('/api/auth/register', data)
  }
}