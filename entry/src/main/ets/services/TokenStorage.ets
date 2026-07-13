import { Context } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';

export class TokenStorage {
  private static readonly STORE_NAME: string = 'zhiyi_auth';
  private static readonly TOKEN_KEY: string = 'token';
  private static readonly NICKNAME_KEY: string = 'nickname';
  private static readonly USER_ID_KEY: string = 'user_id';

  static async saveSession(context: Context, token: string, nickname: string, userId: number): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, TokenStorage.STORE_NAME);
      await store.put(TokenStorage.TOKEN_KEY, token);
      await store.put(TokenStorage.NICKNAME_KEY, nickname);
      await store.put(TokenStorage.USER_ID_KEY, userId);
      await store.flush();
    } catch (error) {
      throw new Error('无法保存本地登录状态');
    }
  }

  static async getUserId(context: Context): Promise<number> {
    try {
      const store = await preferences.getPreferences(context, TokenStorage.STORE_NAME);
      const value = await store.get(TokenStorage.USER_ID_KEY, 0);
      return value as number;
    } catch (error) {
      return 0;
    }
  }

  static async hasToken(context: Context): Promise<boolean> {
    const token = await TokenStorage.getToken(context);
    return token.length > 0;
  }

  static async getToken(context: Context): Promise<string> {
    try {
      const store = await preferences.getPreferences(context, TokenStorage.STORE_NAME);
      const value = await store.get(TokenStorage.TOKEN_KEY, '');
      return value as string;
    } catch (error) {
      return '';
    }
  }

  static async getNickname(context: Context): Promise<string> {
    try {
      const store = await preferences.getPreferences(context, TokenStorage.STORE_NAME);
      const value = await store.get(TokenStorage.NICKNAME_KEY, '记忆守护者');
      return value as string;
    } catch (error) {
      return '记忆守护者';
    }
  }

  static async clearSession(context: Context): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, TokenStorage.STORE_NAME);
      await store.delete(TokenStorage.TOKEN_KEY);
      await store.delete(TokenStorage.NICKNAME_KEY);
      await store.delete(TokenStorage.USER_ID_KEY);
      await store.flush();
    } catch (error) {
      throw new Error('无法清除本地登录状态');
    }
  }
}
