import { Context } from '@kit.AbilityKit';
import { RecallCard } from '../models/RecallCard';
import { RecallCardRepository } from '../repositories/RecallCardRepository';

export class RecallCardGenerateResult {
  success: boolean = false;
  message: string = '';
  card: RecallCard | null = null;

  constructor(success: boolean, message: string, card: RecallCard | null = null) {
    this.success = success;
    this.message = message;
    this.card = card;
  }
}

export class RecallCardViewModel {
  private readonly repository: RecallCardRepository = new RecallCardRepository();

  async generate(context: Context): Promise<RecallCardGenerateResult> {
    const result = await this.repository.generate(context);
    if (result.code === 200 && result.data != null) {
      return new RecallCardGenerateResult(true, '已生成新的回忆总结，快去看看吧！', result.data);
    }
    if (result.message === 'no_new_memories') {
      return new RecallCardGenerateResult(false, '您还没有新的回忆可以总结，快去记录一个吧！');
    }
    return new RecallCardGenerateResult(false, result.message);
  }

  async list(context: Context): Promise<RecallCard[]> {
    const result = await this.repository.list(context);
    return result.data === undefined ? [] : result.data;
  }
}
