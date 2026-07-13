import { Memory } from '../models/Memory';
import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { CreateMemoryRequestBody } from '../models/ApiRequests';

export class MemoryRepository {
  private readonly http: HttpClient = new HttpClient();

  async create(context: Context, content: string, imageUrl: string, mood: string, date: string, hour: number,
    treeHoleId: number = 0): Promise<ApiResult<Memory>> {
    const token = await TokenStorage.getToken(context);
    const body = new CreateMemoryRequestBody(content, imageUrl, mood, date, hour, treeHoleId);
    return this.toMemory(await this.http.post<Memory>(ApiConfig.MEMORIES, body, token));
  }

  async list(context: Context): Promise<ApiResult<Memory[]>> { return this.toMemories(await this.http.get<Memory[]>(ApiConfig.MEMORIES, await TokenStorage.getToken(context))); }
  async getById(context: Context, memoryId: number): Promise<ApiResult<Memory>> { return this.toMemory(await this.http.get<Memory>(`${ApiConfig.MEMORIES}/${memoryId}`, await TokenStorage.getToken(context))); }
  async listByTreeHole(context: Context, treeHoleId: number): Promise<ApiResult<Memory[]>> { return this.toMemories(await this.http.get<Memory[]>(`${ApiConfig.TREE_HOLES}/${treeHoleId}/memories`, await TokenStorage.getToken(context))); }
  async listByDate(context: Context, treeHoleId: number, date: string): Promise<ApiResult<Memory[]>> { return this.toMemories(await this.http.get<Memory[]>(`${ApiConfig.TREE_HOLES}/${treeHoleId}/common-day?date=${date}`, await TokenStorage.getToken(context))); }
  async delete(context: Context, memoryId: number): Promise<ApiResult<void>> { return this.http.delete<void>(`${ApiConfig.MEMORIES}/${memoryId}`, await TokenStorage.getToken(context)); }

  private toMemory(result: ApiResult<Memory>): ApiResult<Memory> { if (result.data === undefined) return result; return new ApiResult<Memory>(result.code, result.message, this.map(result.data)); }
  private toMemories(result: ApiResult<Memory[]>): ApiResult<Memory[]> { if (result.data === undefined) return result; return new ApiResult<Memory[]>(result.code, result.message, result.data.map((item: Memory) => this.map(item))); }
  private map(raw: Memory): Memory {
    const imageUrl = raw.imageUrl.length > 0 && raw.imageUrl.startsWith('/') ? `${ApiConfig.BASE_URL}${raw.imageUrl}` : raw.imageUrl;
    return new Memory(raw.id, raw.authorId, raw.authorName, raw.content, imageUrl, raw.mood, raw.date, raw.hour, raw.createdAt, raw.treeHoleId > 0 ? raw.treeHoleId : 0);
  }
}
