import { Context } from '@kit.AbilityKit';
import { ApiResult } from '../models/ApiResult';
import { TimeCapsule } from '../models/TimeCapsule';
import { CreateTimeCapsuleRequestBody, EmptyRequestBody } from '../models/ApiRequests';
import { ApiConfig } from '../constants/ApiConfig';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';

export class TimeCapsuleRepository {
  private readonly http: HttpClient = new HttpClient();
  async create(context: Context, content: string, mood: string, openAt: string): Promise<ApiResult<TimeCapsule>> {
    return this.one(await this.http.post<TimeCapsule>(ApiConfig.TIME_CAPSULES, new CreateTimeCapsuleRequestBody(content, mood, openAt), await TokenStorage.getToken(context)));
  }
  async list(context: Context): Promise<ApiResult<TimeCapsule[]>> { return this.many(await this.http.get<TimeCapsule[]>(ApiConfig.TIME_CAPSULES, await TokenStorage.getToken(context))); }
  async get(context: Context, id: number): Promise<ApiResult<TimeCapsule>> { return this.one(await this.http.get<TimeCapsule>(`${ApiConfig.TIME_CAPSULES}/${id}`, await TokenStorage.getToken(context))); }
  async open(context: Context, id: number): Promise<ApiResult<TimeCapsule>> { return this.one(await this.http.patch<TimeCapsule>(`${ApiConfig.TIME_CAPSULES}/${id}/open`, new EmptyRequestBody(), await TokenStorage.getToken(context))); }
  private one(result: ApiResult<TimeCapsule>): ApiResult<TimeCapsule> { return result.data === undefined ? result : new ApiResult<TimeCapsule>(result.code, result.message, this.map(result.data)); }
  private many(result: ApiResult<TimeCapsule[]>): ApiResult<TimeCapsule[]> { return result.data === undefined ? result : new ApiResult<TimeCapsule[]>(result.code, result.message, result.data.map((item: TimeCapsule) => this.map(item))); }
  private map(raw: TimeCapsule): TimeCapsule {
    const item = new TimeCapsule();
    item.id = raw.id; item.authorId = raw.authorId; item.authorName = raw.authorName; item.isOpened = raw.isOpened;
    // 兼容尚未升级的服务端：未开启正文即使被返回，也不进入客户端状态。
    item.content = item.isOpened ? raw.content : '';
    item.mood = raw.mood; item.sealDate = raw.sealDate; item.openDate = raw.openDate; item.openAt = raw.openAt;
    item.actualOpenDate = raw.actualOpenDate;
    return item;
  }
}
