import { HttpClient } from './HttpClient'
import { LoginRequest, LoginResponse, RegisterRequest, UserVO, UpdateUserRequest } from '../model/User'

export class AuthApi {
  static async login(data: LoginRequest): Promise<LoginResponse> {
    return HttpClient.post<LoginResponse>('/api/auth/login', data)
  }

  static async register(data: RegisterRequest): Promise<void> {
    return HttpClient.post<void>('/api/auth/app/register', data)
  }

  static async getCurrentUser(): Promise<UserVO> {
    return HttpClient.get<UserVO>('/api/users/me')
  }

  static async updateUser(data: UpdateUserRequest): Promise<void> {
    return HttpClient.put<void>('/api/users/me', data)
  }
}