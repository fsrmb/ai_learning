import { MY_IP as LocalIP } from './EnvConfig.local';

export class Constants {
  // 👇 新增：私有静态方法，判断用本地IP还是默认IP
  private static getEffectiveIP(): string {
    // 如果本地配置存在且不为空，就用本地的；否则用下面的默认值
    if (LocalIP) {
      return LocalIP;
    }
    return '172.19.18.216'; // 你的默认IP（提交到仓库，给没配本地文件的同学保底）
  }
  static readonly MY_IP: string = Constants.getEffectiveIP();
  //static readonly MY_IP: string ='172.19.18.216'
  static readonly BASE_URL: string = `http://${Constants.MY_IP}:8080`;
  static readonly DIFYCHAT_URL: string = `http://${Constants.MY_IP}/v1`;
  //static readonly BASE_URL: string = 'http://172.19.18.216:8080'
  //static readonly LINK_URL: string =
  static readonly TOKEN_KEY: string = 'app-b3e3vd7rYn1PEThoxkGBB7Kf'
  static readonly RESUME_API_URL: string = `http://${Constants.MY_IP}/v1`  // 简历优化 API 地址（Dify Workflow 模式，端点 /v1/workflows/run）
  static readonly RESUME_API_KEY: string = 'app-Rbeph2hyTnyLH3MLkcKYb4VP'    // 简历优化 API 密钥（待填写）
  static readonly USER_ID_KEY: string = 'ai_app_user_id'
  static readonly USERNAME_KEY: string = 'ai_app_username'
  static readonly PASSWORD_KEY: string = 'ai_app_password'
  static readonly REMEMBER_ME_KEY: string = 'ai_app_remember_me'
  static readonly USER_INFO_KEY: string = 'ai_app_user_info'
  static readonly PREFERENCES_NAME: string = 'ai_app_preferences'
  static readonly TIMEOUT: number = 15000                    // 超时时间 15秒
}
