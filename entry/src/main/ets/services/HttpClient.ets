import { ApiResult } from '../models/ApiResult';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiConfig } from '../constants/ApiConfig';

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
    const startTs: number = Date.now();
    const request: http.HttpRequest = http.createHttp();
    try {
      console.info(`[HttpClient] upload START url=${url} file=${fileName} type=${contentType}`);
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.POST,
        // NetStack 的默认 Content-Type 是 application/json。只有精确设为
        // multipart/form-data 时，multiFormDataList 才会生效并由 SDK 生成 boundary。
        header: this.multipartHeaders(token),
        multiFormDataList: [{
          name: 'file',
          contentType: contentType,
          remoteFileName: fileName,
          filePath: localPath
        }],
        usingCache: false,
        connectTimeout: 10000,
        readTimeout: 60000
      });

      const elapsed: number = Date.now() - startTs;
      console.info(`[HttpClient] upload DONE code=${response.responseCode} elapsed=${elapsed}ms`);
      return this.parse<ImageUploadData>(response.result, response.responseCode);
    } catch (error) {
      const code: number = (error as BusinessError).code;
      console.error(`[HttpClient] upload ERROR code=${code}`);
      if (code === 2300028) {
        return new ApiResult<ImageUploadData>(0,
          `图片上传超时（${code}），当前服务器为 ${ApiConfig.BASE_URL}`);
      }
      if (code === 2300001 || code === 2300998) {
        return new ApiResult<ImageUploadData>(0,
          `无法连接 ${ApiConfig.BASE_URL}（${code}），请检查工具箱中的服务器地址`);
      }
      if (code === 2300025 || code === 2300026) {
        return new ApiResult<ImageUploadData>(0, `上传缓存文件不可读（${code}），请重新选择照片`);
      }
      return new ApiResult<ImageUploadData>(0,
        `图片上传失败（网络错误 ${code}），请重试`);
    } finally {
      request.destroy();
    }
  }

  private async request<T>(
    path: string,
    method: http.RequestMethod,
    body: Object | undefined,
    token: string
  ): Promise<ApiResult<T>> {
    const request: http.HttpRequest = http.createHttp();
    try {
      const response: http.HttpResponse = await request.request(this.url(path), {
        method: method,
        header: this.jsonHeaders(token),
        extraData: body === undefined ? undefined : JSON.stringify(body),
        connectTimeout: 5000,
        readTimeout: 30000
      });
      return this.parse<T>(response.result, response.responseCode);
    } catch (error) {
      const code: number = (error as BusinessError).code;
      if (code === 2300001 || code === 2300998 || code === 2300028) {
        return new ApiResult<T>(0, '无法连接到服务器，请检查手机与后端是否在同一 Wi-Fi');
      }
      return new ApiResult<T>(0, `网络请求失败（${code !== undefined ? code : '未知'}）`);
    } finally {
      request.destroy();
    }
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

  private parse<T>(raw: string | Object, responseCode: number): ApiResult<T> {
    try {
      const text: string = typeof raw === 'string' ? raw : JSON.stringify(raw);
      const result: ApiResult<T> = JSON.parse(text) as ApiResult<T>;
      if (result.code === undefined) {
        return new ApiResult<T>(responseCode, '服务器返回格式不正确');
      }
      return result;
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
