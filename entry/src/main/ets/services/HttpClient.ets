import { ApiResult } from '../models/ApiResult';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiConfig } from '../constants/ApiConfig';

const HARD_TIMEOUT_MS = 10000;

interface ApiResponseJson {
  code: number;
  message: string;
  data: Object;
}

export class ImageUploadData {
  imageUrl: string = '';
}

export class HttpClient {
  async get<T>(path: string, token: string): Promise<ApiResult<T>> {
    return this.request<T>(path, http.RequestMethod.GET, undefined, token);
  }

  async post<T>(path: string, body: Object, token: string = ''): Promise<ApiResult<T>> {
    return this.request<T>(path, http.RequestMethod.POST, body, token);
  }

  async patch<T>(path: string, body: Object, token: string): Promise<ApiResult<T>> {
    return this.request<T>(path, http.RequestMethod.PATCH, body, token);
  }

  async delete<T>(path: string, token: string): Promise<ApiResult<T>> {
    return this.request<T>(path, http.RequestMethod.DELETE, undefined, token);
  }

  async uploadImage(localPath: string, token: string): Promise<ApiResult<ImageUploadData>> {
    return this.uploadImageFile(localPath, token, this.imageContentType(localPath), this.imageFileName(localPath));
  }

  async uploadImageFile(
    localPath: string,
    token: string,
    contentType: string,
    fileName: string
  ): Promise<ApiResult<ImageUploadData>> {
    const url: string = this.url(ApiConfig.IMAGE_UPLOAD);
    const httpReq: http.HttpRequest = http.createHttp();
    return new Promise<ApiResult<ImageUploadData>>((resolve: (value: ApiResult<ImageUploadData>) => void) => {
      let settled: boolean = false;

      const timer: number = setTimeout(() => {
        if (!settled) {
          settled = true;
          httpReq.destroy();
          resolve(new ApiResult<ImageUploadData>(0, '上传超时，请检查服务器地址或网络'));
        }
      }, 30000);

      httpReq.request(url, {
        method: http.RequestMethod.POST,
        header: this.multipartHeaders(token),
        multiFormDataList: [{
          name: 'file',
          contentType: contentType,
          remoteFileName: fileName,
          filePath: localPath
        }],
        usingCache: false,
        connectTimeout: 5000,
        readTimeout: 30000
      }).then((response: http.HttpResponse) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          resolve(this.parse<ImageUploadData>(response.result, response.responseCode));
        }
      }).catch((error: BusinessError) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          const code: number = error.code;
          if (code === 2300028) {
            resolve(new ApiResult<ImageUploadData>(0,
              `图片上传超时（${code}），当前服务器为 ${ApiConfig.BASE_URL}`));
            return;
          }
          if (code === 2300001 || code === 2300998) {
            resolve(new ApiResult<ImageUploadData>(0,
              `无法连接 ${ApiConfig.BASE_URL}（${code}），请检查工具箱中的服务器地址`));
            return;
          }
          if (code === 2300025 || code === 2300026) {
            resolve(new ApiResult<ImageUploadData>(0, `上传缓存文件不可读（${code}），请重新选择照片`));
            return;
          }
          resolve(new ApiResult<ImageUploadData>(0,
            `图片上传失败（网络错误 ${code}），请重试`));
        }
      });
    });
  }

  private request<T>(
    path: string,
    method: http.RequestMethod,
    body: Object | undefined,
    token: string
  ): Promise<ApiResult<T>> {
    const httpReq: http.HttpRequest = http.createHttp();
    const fullUrl: string = this.url(path);

    return new Promise<ApiResult<T>>((resolve: (value: ApiResult<T>) => void) => {
      let settled: boolean = false;

      // 硬超时：10 秒内必须有结果，不依赖底层 TCP 栈的超时行为
      const timer: number = setTimeout(() => {
        if (!settled) {
          settled = true;
          httpReq.destroy();
          resolve(new ApiResult<T>(0, '连接超时，请检查服务器地址或网络'));
        }
      }, HARD_TIMEOUT_MS);

      console.info(`[HttpClient] REQUEST ${method} ${fullUrl}`);
      httpReq.request(fullUrl, {
        method: method,
        header: this.jsonHeaders(token),
        extraData: body === undefined ? undefined : JSON.stringify(body),
        connectTimeout: 5000,
        readTimeout: 10000
      }).then((response: http.HttpResponse) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          console.info(`[HttpClient] RESPONSE ${response.responseCode}`);
          // 显式处理 4xx/5xx HTTP 状态码
          if (response.responseCode >= 400) {
            const body = HttpClient.parseBody(response.result);
            const msg: string = body && body.length > 0 ? body : '服务器返回错误';
            resolve(new ApiResult<T>(response.responseCode, msg));
            return;
          }
          resolve(this.parse<T>(response.result, response.responseCode));
        }
      }).catch((error: BusinessError) => {
        if (!settled) {
          settled = true;
          clearTimeout(timer);
          console.error(`[HttpClient] ERROR code=${error.code} msg=${error.message}`);
          // HTTP 错误响应可能走 catch，尝试从 error 中提取消息
          const msg: string = HttpClient.extractErrorBody(error);
          if (msg.length > 0) {
            resolve(new ApiResult<T>(0, msg));
            return;
          }
          const code: number = error.code;
          if (code === 2300001 || code === 2300998 || code === 2300028) {
            resolve(new ApiResult<T>(0, '无法连接到服务器，请检查手机与后端是否在同一 Wi-Fi'));
            return;
          }
          resolve(new ApiResult<T>(0, `网络请求失败（${code !== undefined ? code : '未知'}）`));
        }
      });
    });
  }

  private jsonHeaders(token: string): Record<string, string> {
    const h: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token.length > 0) {
      h['Authorization'] = `Bearer ${token}`;
    }
    return h;
  }

  private multipartHeaders(token: string): Record<string, string> {
    const h: Record<string, string> = { 'Content-Type': 'multipart/form-data' };
    if (token.length > 0) {
      h['Authorization'] = `Bearer ${token}`;
    }
    return h;
  }

  private static parseBody(raw: string | Object): string {
    try {
      const text: string = typeof raw === 'string' ? raw : JSON.stringify(raw);
      const obj: ApiResponseJson = JSON.parse(text) as ApiResponseJson;
      return obj.message;
    } catch (e) {
      // not JSON
    }
    return '';
  }

  private static extractErrorBody(error: BusinessError): string {
    try {
      const msg: string = error.message;
      if (msg.length > 0 && msg.startsWith('{')) {
        const obj: ApiResponseJson = JSON.parse(msg) as ApiResponseJson;
        return obj.message;
      }
    } catch (e) {
      // ignore
    }
    return '';
  }

  private parse<T>(raw: string | Object, responseCode: number): ApiResult<T> {
    try {
      const text: string = typeof raw === 'string' ? raw : JSON.stringify(raw);
      const obj: ApiResponseJson = JSON.parse(text) as ApiResponseJson;
      return new ApiResult<T>(obj.code, obj.message, obj.data as T);
    } catch (e) {
      return new ApiResult<T>(responseCode, responseCode >= 500 ? '服务器处理失败' : '服务器返回格式不正确');
    }
  }

  private url(path: string): string {
    return path.startsWith('http') ? path : `${ApiConfig.BASE_URL}${path}`;
  }

  private imageContentType(path: string): string {
    const lower: string = path.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  private imageFileName(path: string): string {
    const slash: number = path.lastIndexOf('/');
    const name: string = slash >= 0 ? path.substring(slash + 1) : path;
    return name.length > 0 ? name : `memory-${Date.now()}.jpg`;
  }
}
