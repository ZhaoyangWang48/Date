import { AgentChatResponse } from '../models/AgentChat';
import { AgentRepository } from '../repositories/AgentRepository';
import { Context } from '@kit.AbilityKit';

export class AgentViewModel {
  private readonly repository: AgentRepository = new AgentRepository();

  async chat(context: Context, treeHoleId: number, question: string): Promise<AgentChatResponse | undefined> {
    const result = await this.repository.chat(context, treeHoleId, question);
    return result.data;
  }
}
