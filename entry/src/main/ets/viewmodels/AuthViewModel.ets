import { Context } from '@kit.AbilityKit';
import { AuthRepository } from '../repositories/AuthRepository';
import { TokenStorage } from '../services/TokenStorage';

export class AuthActionResult {
  success: boolean = false;
  message: string = '';

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }
}

export class AuthViewModel {
  private readonly repository: AuthRepository = new AuthRepository();

  async login(context: Context, username: string, password: string): Promise<AuthActionResult> {
    const normalizedUsername = username.trim();
    if (normalizedUsername.length === 0 || password.length === 0) {
      return new AuthActionResult(false, '请输入用户名和密码');
    }

    const result = await this.repository.login(normalizedUsername, password);
    const data = result.data;
    if (result.code !== 200 || data === undefined) {
      return new AuthActionResult(false, result.message);
    }

    try {
      await TokenStorage.saveSession(context, data.token, data.user.nickname, data.user.id);
      return new AuthActionResult(true, result.message);
    } catch (error) {
      return new AuthActionResult(false, '登录状态保存失败，请重试');
    }
  }

  async register(context: Context, username: string, password: string, confirmPassword: string,
    nickname: string): Promise<AuthActionResult> {
    const normalizedUsername = username.trim();
    const normalizedNickname = nickname.trim();
    if (normalizedUsername.length < 3) {
      return new AuthActionResult(false, '用户名至少需要 3 个字符');
    }
    if (normalizedNickname.length === 0) {
      return new AuthActionResult(false, '请填写昵称');
    }
    if (password.length < 6) {
      return new AuthActionResult(false, '密码至少需要 6 个字符');
    }
    if (password !== confirmPassword) {
      return new AuthActionResult(false, '两次输入的密码不一致');
    }

    const result = await this.repository.register(normalizedUsername, password, normalizedNickname);
    const data = result.data;
    if (result.code !== 200 || data === undefined) {
      return new AuthActionResult(false, result.message);
    }

    try {
      await TokenStorage.saveSession(context, data.token, data.user.nickname, data.user.id);
      return new AuthActionResult(true, result.message);
    } catch (error) {
      return new AuthActionResult(false, '注册状态保存失败，请重试');
    }
  }
}
