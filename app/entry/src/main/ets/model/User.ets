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

export class UserVO {
  id: number = 0
  username: string = ''
  nickname: string = ''
  email: string = ''
  phone: string = ''
  avatar: string = ''
  role: string = ''
  status: number = 0
  createTime: string = ''
  updateTime: string = ''
}

export class LoginResponse {
  token: string = ''
  user: UserVO = new UserVO()
}

export class RegisterRequest {
  username: string = ''
  password: string = ''
  email: string = ''
  nickname: string = ''
}

export class UpdateUserRequest {
  nickname: string = ''
  email: string = ''
  phone: string = ''
}