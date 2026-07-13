export class ApiConfig {
  static readonly DEFAULT_BASE_URL: string = 'http://127.0.0.1:8080';
  // 启动时从本机 preferences 读取；可在“我的”页面修改。
  static BASE_URL: string = ApiConfig.DEFAULT_BASE_URL;

  static setBaseUrl(value: string): void {
    ApiConfig.BASE_URL = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static readonly AUTH_LOGIN: string = '/api/auth/login';
  static readonly AUTH_REGISTER: string = '/api/auth/register';
  static readonly USER_ME: string = '/api<REDACTED_LOCAL_PATH>';
  static readonly MEMORIES: string = '/api/memories';
  static readonly TREE_HOLES: string = '/api/tree-holes';
  static readonly IMAGE_UPLOAD: string = '/api/files/images';
}
