import { Context } from '@kit.AbilityKit';
import { ApiConfig } from '../constants/ApiConfig';
import { GenerateMemoryDraftRequestBody } from '../models/ApiRequests';
import { ApiResult } from '../models/ApiResult';
import { MemoryDraft } from '../models/MemoryDraft';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';

const AI_TIMEOUT_MS: number = 95000;

export class MemoryDraftRepository {
  private readonly http: HttpClient = new HttpClient();

  async generate(context: Context, imageUrl: string, capturedAt: string): Promise<ApiResult<MemoryDraft>> {
    const token: string = await TokenStorage.getToken(context);
    if (token.length === 0) {
      return new ApiResult<MemoryDraft>(401, '未登录，请先登录');
    }
    return this.http.postWithTimeout<MemoryDraft>(
      ApiConfig.MEMORY_DRAFT,
      new GenerateMemoryDraftRequestBody(imageUrl, capturedAt),
      token,
      AI_TIMEOUT_MS
    );
  }
}
