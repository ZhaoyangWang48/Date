import { AgentChatResponse } from '../models/AgentChat';
import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { AgentChatRequestBody } from '../models/ApiRequests';

export class AgentRepository {
  private readonly http: HttpClient = new HttpClient();

  async chat(context: Context, treeHoleId: number, question: string): Promise<ApiResult<AgentChatResponse>> {
    return this.normalize(await this.http.post<AgentChatResponse>(
      ApiConfig.AGENT_CHAT,
      new AgentChatRequestBody(treeHoleId, question),
      await TokenStorage.getToken(context)));
  }

  private normalize(result: ApiResult<AgentChatResponse>): ApiResult<AgentChatResponse> {
    if (result.data === undefined) return result;
    return new ApiResult<AgentChatResponse>(result.code, result.message, result.data);
  }
}
