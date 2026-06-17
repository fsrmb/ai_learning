export class Constants {
  //实际IP地址
  static readonly BASE_URL: string = 'http://192.168.100.100:8080'
  static readonly TOKEN_KEY: string = 'ai_app_token'
  static readonly USER_ID_KEY: string = 'ai_app_user_id'
  static readonly USERNAME_KEY: string = 'ai_app_username'
  static readonly PASSWORD_KEY: string = 'ai_app_password'
  static readonly REMEMBER_ME_KEY: string = 'ai_app_remember_me'
  static readonly USER_INFO_KEY: string = 'ai_app_user_info'
  static readonly PREFERENCES_NAME: string = 'ai_app_preferences'
  static readonly TIMEOUT: number = 15000                    // 超时时间 15秒
}
