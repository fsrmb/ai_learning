import { preferences } from '@kit.ArkData'
import GlobalContext from './GlobalContext'
import { Constants } from './Constants'

// 定义登录凭证接口
export class LoginCredentials {
  username: string = ''
  password: string = ''
  rememberMe: boolean = false

  constructor(username: string = '', password: string = '', rememberMe: boolean = false) {
    this.username = username
    this.password = password
    this.rememberMe = rememberMe
  }
}

export class TokenUtil {
  private static preferencesManager: preferences.Preferences | null = null

  private static async getPreferences(): Promise<preferences.Preferences> {
    if (!TokenUtil.preferencesManager) {
      const context = GlobalContext.getInstance().getContext()
      if (!context) {
        console.error('TokenUtil: Context not initialized')
        throw new Error('Context not initialized')
      }
      try {
        TokenUtil.preferencesManager = await preferences.getPreferences(context, Constants.PREFERENCES_NAME)
        console.info('TokenUtil: Preferences initialized successfully')
      } catch (err) {
        const errorMessage = err instanceof Error ? err.message : 'Unknown error'
        console.error('TokenUtil: Failed to get preferences:', errorMessage)
        throw new Error(errorMessage)
      }
    }
    return TokenUtil.preferencesManager
  }

  static async getToken(): Promise<string> {
    try {
      const pref = await TokenUtil.getPreferences()
      const token = await pref.get(Constants.TOKEN_KEY, '')
      return token as string
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil getToken failed:', errorMessage)
      return ''
    }
  }

  static async setToken(token: string): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.put(Constants.TOKEN_KEY, token)
      await pref.flush()
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil setToken failed:', errorMessage)
    }
  }

  static async removeToken(): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.delete(Constants.TOKEN_KEY)
      await pref.flush()
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil removeToken failed:', errorMessage)
    }
  }

  static async hasToken(): Promise<boolean> {
    const token = await TokenUtil.getToken()
    return token !== ''
  }

  static async saveUserInfo(userId: number, username: string): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.put(Constants.USER_ID_KEY, userId.toString())
      await pref.put(Constants.USERNAME_KEY, username)
      await pref.flush()
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil saveUserInfo failed:', errorMessage)
    }
  }

  static async saveNickname(nickname: string): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.put(Constants.NICKNAME_KEY, nickname)
      await pref.flush()
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil saveNickname failed:', errorMessage)
    }
  }

  static async getNickname(): Promise<string> {
    try {
      const pref = await TokenUtil.getPreferences()
      const nickname = await pref.get(Constants.NICKNAME_KEY, '')
      return nickname as string
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil getNickname failed:', errorMessage)
      return ''
    }
  }

  static async getUsername(): Promise<string> {
    try {
      const pref = await TokenUtil.getPreferences()
      const username = await pref.get(Constants.USERNAME_KEY, '')
      return username as string
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil getUsername failed:', errorMessage)
      return ''
    }
  }

  static async getUserId(): Promise<number> {
    try {
      const pref = await TokenUtil.getPreferences()
      const userId = await pref.get(Constants.USER_ID_KEY, '0')
      return parseInt(userId as string, 10)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil getUserId failed:', errorMessage)
      return 0
    }
  }

  static async clearAll(): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.clear()
      await pref.flush()
      TokenUtil.preferencesManager = null
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil clearAll failed:', errorMessage)
    }
  }

  // 保存登录凭证（用户名、密码、记住密码状态）
  static async saveLoginCredentials(username: string, password: string, rememberMe: boolean): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.put(Constants.USERNAME_KEY, username)
      await pref.put(Constants.PASSWORD_KEY, password)
      await pref.put(Constants.REMEMBER_ME_KEY, rememberMe.toString())
      await pref.flush()
      console.info('TokenUtil: saveLoginCredentials succeeded')
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil saveLoginCredentials failed:', errorMessage)
    }
  }

  // 获取保存的登录凭证
  static async getLoginCredentials(): Promise<LoginCredentials> {
    try {
      const pref = await TokenUtil.getPreferences()
      const username = await pref.get(Constants.USERNAME_KEY, '') as string
      const password = await pref.get(Constants.PASSWORD_KEY, '') as string
      const rememberMeStr = await pref.get(Constants.REMEMBER_ME_KEY, 'false') as string
      const rememberMe = rememberMeStr === 'true'
      return new LoginCredentials(username, password, rememberMe)
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil getLoginCredentials failed:', errorMessage)
      return new LoginCredentials('', '', false)
    }
  }

  // 清除登录凭证（但不清除 Token）
  static async clearLoginCredentials(): Promise<void> {
    try {
      const pref = await TokenUtil.getPreferences()
      await pref.delete(Constants.USERNAME_KEY)
      await pref.delete(Constants.PASSWORD_KEY)
      await pref.delete(Constants.REMEMBER_ME_KEY)
      await pref.flush()
      console.info('TokenUtil: clearLoginCredentials succeeded')
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error('TokenUtil clearLoginCredentials failed:', errorMessage)
    }
  }
}