import { ApiResult } from '../models/ApiResult';
import { RecallCard } from '../models/RecallCard';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { Context } from '@kit.AbilityKit';

class GenerateRecallCardBody {
  treeHoleId: number = 0;
}

export class RecallCardRepository {
  private readonly http: HttpClient = new HttpClient();

  async generate(context: Context): Promise<ApiResult<RecallCard>> {
    const token = await TokenStorage.getToken(context);
    const body = new GenerateRecallCardBody();
    body.treeHoleId = 0;
    const result = await this.http.post<RecallCard>(ApiConfig.RECALL_CARDS_GENERATE, body, token);
    if (result.data != null) {
      return new ApiResult<RecallCard>(result.code, result.message, this.map(result.data));
    }
    return result;
  }

  async list(context: Context): Promise<ApiResult<RecallCard[]>> {
    const token = await TokenStorage.getToken(context);
    const result = await this.http.get<RecallCard[]>(ApiConfig.RECALL_CARDS, token);
    if (result.data != null) {
      return new ApiResult<RecallCard[]>(result.code, result.message,
        result.data.map((item: RecallCard) => this.map(item)));
    }
    return new ApiResult<RecallCard[]>(result.code, result.message, undefined);
  }

  private map(raw: RecallCard): RecallCard {
    return new RecallCard(raw.id, raw.userId, raw.treeHoleId, raw.title, raw.summary,
      raw.moodTags, raw.representativeImageUrl, raw.timeRangeStart, raw.timeRangeEnd,
      raw.memoryCount, raw.createdAt);
  }
}
