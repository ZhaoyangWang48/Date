import { Context } from '@kit.AbilityKit';
import { ApiConfig } from '../constants/ApiConfig';
import { ApiResult } from '../models/ApiResult';
import { DriftBottle, ResonanceLeaf } from '../models/DriftBottle';
import { SendResonanceRequestBody, ThrowBottleRequestBody } from '../models/ApiRequests';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';

export class PickupCount { count: number = 0; }

export class DriftBottleRepository {
  private readonly http: HttpClient = new HttpClient();
  async throwBottle(context: Context, memoryId: number, content: string, mood: string): Promise<ApiResult<DriftBottle>> { return this.bottle(await this.http.post<DriftBottle>(ApiConfig.BOTTLES, new ThrowBottleRequestBody(memoryId, content, mood), await TokenStorage.getToken(context))); }
  async pickup(context: Context): Promise<ApiResult<DriftBottle>> { return this.bottle(await this.http.get<DriftBottle>(`${ApiConfig.BOTTLES}/random`, await TokenStorage.getToken(context))); }
  async resonate(context: Context, bottleId: number, mood: string): Promise<ApiResult<ResonanceLeaf>> { return this.leaf(await this.http.post<ResonanceLeaf>(`${ApiConfig.BOTTLES}/${bottleId}/resonance`, new SendResonanceRequestBody(mood), await TokenStorage.getToken(context))); }
  async mine(context: Context): Promise<ApiResult<DriftBottle[]>> { const result = await this.http.get<DriftBottle[]>(`${ApiConfig.BOTTLES}/mine`, await TokenStorage.getToken(context)); return result.data === undefined ? result : new ApiResult<DriftBottle[]>(result.code, result.message, result.data.map((item: DriftBottle) => this.mapBottle(item))); }
  async resonances(context: Context): Promise<ApiResult<ResonanceLeaf[]>> { const result = await this.http.get<ResonanceLeaf[]>(`${ApiConfig.BOTTLES}/mine/resonances`, await TokenStorage.getToken(context)); return result.data === undefined ? result : new ApiResult<ResonanceLeaf[]>(result.code, result.message, result.data.map((item: ResonanceLeaf) => this.mapLeaf(item))); }
  async pickupCount(context: Context): Promise<ApiResult<PickupCount>> { return this.http.get<PickupCount>(`${ApiConfig.BOTTLES}/pickup-count`, await TokenStorage.getToken(context)); }
  private bottle(result: ApiResult<DriftBottle>): ApiResult<DriftBottle> { return result.data === undefined ? result : new ApiResult<DriftBottle>(result.code, result.message, this.mapBottle(result.data)); }
  private leaf(result: ApiResult<ResonanceLeaf>): ApiResult<ResonanceLeaf> { return result.data === undefined ? result : new ApiResult<ResonanceLeaf>(result.code, result.message, this.mapLeaf(result.data)); }
  private mapBottle(raw: DriftBottle): DriftBottle { const item = new DriftBottle(); item.id = raw.id; item.content = raw.content; item.mood = raw.mood; item.throwTime = raw.throwTime; item.expireTime = raw.expireTime; item.isPickedUp = raw.isPickedUp; item.resonanceCount = raw.resonanceCount; return item; }
  private mapLeaf(raw: ResonanceLeaf): ResonanceLeaf { const item = new ResonanceLeaf(); item.id = raw.id; item.bottleId = raw.bottleId; item.mood = raw.mood; item.timestamp = raw.timestamp; item.bottleContentSnippet = raw.bottleContentSnippet; return item; }
}
