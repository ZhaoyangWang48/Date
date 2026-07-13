import { ApiResult } from '../models/ApiResult';
import { AuthData } from '../models/AuthData';
import { User } from '../models/User';
import { HttpClient } from '../services/HttpClient';
import { ApiConfig } from '../constants/ApiConfig';
import { LoginRequestBody, RegisterRequestBody } from '../models/ApiRequests';

export class AuthRepository {
  private readonly http: HttpClient = new HttpClient();

  async login(username: string, password: string): Promise<ApiResult<AuthData>> {
    const result = await this.http.post<AuthData>(ApiConfig.AUTH_LOGIN, new LoginRequestBody(username, password));
    return this.normalize(result);
  }

  async register(username: string, password: string, nickname: string): Promise<ApiResult<AuthData>> {
    const result = await this.http.post<AuthData>(ApiConfig.AUTH_REGISTER, new RegisterRequestBody(username, password, nickname));
    return this.normalize(result);
  }

  private normalize(result: ApiResult<AuthData>): ApiResult<AuthData> {
    if (result.data === undefined) return result;
    const raw = result.data as AuthData;
    const user = raw.user as User;
    return new ApiResult<AuthData>(result.code, result.message, new AuthData(raw.token,
      new User(user.id, user.username, user.nickname, user.avatarUrl)));
  }
}
