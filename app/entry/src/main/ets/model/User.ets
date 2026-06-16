export class User {
  id: number = 0
  username: string = ''
  nickname: string = ''
  email: string = ''
  role: string = ''
  avatar: string = ''
  createdAt: string = ''
}

export class LoginRequest {
  username: string = ''
  password: string = ''
}

export class LoginResponse {
  token: string = ''
  userId: number = 0
  username: string = ''
  role: string = ''
}

export class RegisterRequest {
  username: string = ''
  password: string = ''
  email: string = ''
  nickname: string = ''
}
