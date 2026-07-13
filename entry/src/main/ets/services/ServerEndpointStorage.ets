import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { ApiConfig } from '../constants/ApiConfig';

export class ServerEndpointStorage {
  private static readonly STORE_NAME: string = 'zhiyi_settings';
  private static readonly BASE_URL_KEY: string = 'base_url';
  private static readonly LEGACY_BASE_URLS: string[] = [
    'http://127.0.0.1:8080'
  ];

  static async load(context: Context): Promise<string> {
    try {
      const store = await preferences.getPreferences(context, ServerEndpointStorage.STORE_NAME);
      const saved = await store.get(ServerEndpointStorage.BASE_URL_KEY, ApiConfig.DEFAULT_BASE_URL) as string;
      const normalized: string = ServerEndpointStorage.normalize(saved);
      const needsMigration: boolean = ServerEndpointStorage.LEGACY_BASE_URLS.indexOf(normalized) >= 0;
      const endpoint: string = normalized.length > 0 && !needsMigration ? normalized : ApiConfig.DEFAULT_BASE_URL;
      if (needsMigration) {
        await store.put(ServerEndpointStorage.BASE_URL_KEY, endpoint);
        await store.flush();
      }
      ApiConfig.setBaseUrl(endpoint);
      return endpoint;
    } catch (_error) {
      ApiConfig.setBaseUrl(ApiConfig.DEFAULT_BASE_URL);
      return ApiConfig.DEFAULT_BASE_URL;
    }
  }

  static async save(context: Context, value: string): Promise<string> {
    const normalized = ServerEndpointStorage.normalize(value);
    if (normalized.length === 0) return '';
    try {
      const store = await preferences.getPreferences(context, ServerEndpointStorage.STORE_NAME);
      await store.put(ServerEndpointStorage.BASE_URL_KEY, normalized);
      await store.flush();
      ApiConfig.setBaseUrl(normalized);
      return normalized;
    } catch (_error) {
      return '';
    }
  }

  private static normalize(value: string): string {
    const url = value.trim();
    if (!/^https?:\/\/[^\s/:]+(?::\d{1,5})?$/.test(url)) {
      return '';
    }
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
