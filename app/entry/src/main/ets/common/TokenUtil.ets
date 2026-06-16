import { preferences } from '@kit.ArkData'
import { Constants } from './Constants'
import GlobalContext from './GlobalContext'

export class TokenUtil {
  private static preferencesManager: preferences.Preferences | null = null

  private static async getPreferences(): Promise<preferences.Preferences> {
    if (!TokenUtil.preferencesManager) {
      const context = GlobalContext.getInstance().getContext()
      if (!context) {
        throw new Error('Context not initialized')
      }
      TokenUtil.preferencesManager = await preferences.getPreferences(context, Constants.PREFERENCES_NAME)
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
}