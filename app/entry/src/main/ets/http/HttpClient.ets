import { http } from '@kit.NetworkKit'
import { Constants } from '../common/Constants'
import { TokenUtil } from '../common/TokenUtil'

interface ApiResponse<T> {
  code: number
  message: string
  data: T
}

export class HttpClient {
  static async get<T>(path: string): Promise<T> {
    const token = await TokenUtil.getToken()
    const response = await http.createHttp().request(`${Constants.BASE_URL}${path}`, {
      method: http.RequestMethod.GET,
      header: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json'
      }
    })
    return HttpClient.handleResponse<T>(response)
  }

  static async post<T>(path: string, data: object): Promise<T> {
    const token = await TokenUtil.getToken()
    const response = await http.createHttp().request(`${Constants.BASE_URL}${path}`, {
      method: http.RequestMethod.POST,
      header: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify(data)
    })
    return HttpClient.handleResponse<T>(response)
  }

  static async put<T>(path: string, data: object): Promise<T> {
    const token = await TokenUtil.getToken()
    const response = await http.createHttp().request(`${Constants.BASE_URL}${path}`, {
      method: http.RequestMethod.PUT,
      header: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json'
      },
      extraData: JSON.stringify(data)
    })
    return HttpClient.handleResponse<T>(response)
  }

  static async delete<T>(path: string): Promise<T> {
    const token = await TokenUtil.getToken()
    const response = await http.createHttp().request(`${Constants.BASE_URL}${path}`, {
      method: http.RequestMethod.DELETE,
      header: {
        'Authorization': token ? `Bearer ${token}` : '',
        'Content-Type': 'application/json'
      }
    })
    return HttpClient.handleResponse<T>(response)
  }

  private static handleResponse<T>(response: http.HttpResponse): T {
    if (response.responseCode === 200) {
      const result = JSON.parse(response.result as string) as ApiResponse<T>
      if (result.code === 200) {
        return result.data
      } else {
        throw new Error(result.message || '请求失败')
      }
    } else {
      throw new Error(`HTTP error: ${response.responseCode}`)
    }
  }
}
