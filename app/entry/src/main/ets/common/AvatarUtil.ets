import { fileIo as fs } from '@kit.CoreFileKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import GlobalContext from './GlobalContext'

export class AvatarUtil {
  private static readonly AVATAR_DIR: string = 'avatars'
  private static readonly AVATAR_PREFIX: string = 'avatar_'

  private static getAvatarDirPath(): string {
    const context = GlobalContext.getInstance().getContext()
    if (!context) {
      throw new Error('Context not initialized')
    }
    const filesDir = context.filesDir
    const avatarDir = `${filesDir}/${AvatarUtil.AVATAR_DIR}`
    return avatarDir
  }

  private static async ensureAvatarDir(): Promise<void> {
    const avatarDir = AvatarUtil.getAvatarDirPath()
    try {
      const stat = fs.statSync(avatarDir)
      if (!stat.isDirectory) {
        fs.mkdirSync(avatarDir)
      }
    } catch (err) {
      fs.mkdirSync(avatarDir)
    }
  }

  private static generateAvatarName(username: string): string {
    const sanitizedUsername = username.replace(/[^a-zA-Z0-9_]/g, '_')
    return `${AvatarUtil.AVATAR_PREFIX}${sanitizedUsername}.jpg`
  }

  private static getAvatarFilePath(username: string): string {
    const avatarDir = AvatarUtil.getAvatarDirPath()
    const avatarName = AvatarUtil.generateAvatarName(username)
    return `${avatarDir}/${avatarName}`
  }

  static async saveAvatar(sourceUri: string, username: string): Promise<string> {
    await AvatarUtil.ensureAvatarDir()

    const destPath = AvatarUtil.getAvatarFilePath(username)
    const fileUri = `file://${destPath}`

    try {
      AvatarUtil.deleteAvatarIfExists(fileUri)

      const sourceFile = fs.openSync(sourceUri, fs.OpenMode.READ_ONLY)
      const destFile = fs.openSync(destPath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY)

      const bufferSize = 4096
      let buffer = new ArrayBuffer(bufferSize)
      let readSize: number = fs.readSync(sourceFile.fd, buffer)

      while (readSize > 0) {
        fs.writeSync(destFile.fd, buffer, { length: readSize })
        buffer = new ArrayBuffer(bufferSize)
        readSize = fs.readSync(sourceFile.fd, buffer)
      }

      fs.closeSync(sourceFile)
      fs.closeSync(destFile)

      console.info(`AvatarUtil: Avatar saved successfully - ${fileUri}`)
      return fileUri
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error'
      console.error(`AvatarUtil: Failed to save avatar - ${errorMessage}`)
      throw new Error(`保存头像失败: ${errorMessage}`)
    }
  }

  static deleteAvatarIfExists(avatarUri: string): void {
    if (!avatarUri || avatarUri === '') {
      return
    }
    const filePath = avatarUri.replace('file://', '')
    try {
      fs.unlinkSync(filePath)
      console.info(`AvatarUtil: Deleted old avatar - ${filePath}`)
    } catch (err) {
      console.warn(`AvatarUtil: Avatar not found or already deleted - ${filePath}`)
    }
  }

  static avatarExists(avatarUri: string): boolean {
    if (!avatarUri || avatarUri === '') {
      return false
    }
    const filePath = avatarUri.replace('file://', '')
    try {
      fs.statSync(filePath)
      return true
    } catch (err) {
      return false
    }
  }
}