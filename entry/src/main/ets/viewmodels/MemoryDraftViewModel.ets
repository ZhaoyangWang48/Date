import { Context } from '@kit.AbilityKit';
import { MemoryDraftRepository } from '../repositories/MemoryDraftRepository';

export class MemoryDraftActionResult {
  success: boolean = false;
  message: string = '';
  content: string = '';

  constructor(success: boolean, message: string, content: string = '') {
    this.success = success;
    this.message = message;
    this.content = content;
  }
}

export class MemoryDraftViewModel {
  private readonly repository: MemoryDraftRepository = new MemoryDraftRepository();

  async generate(context: Context, imageUrl: string, capturedAt: string): Promise<MemoryDraftActionResult> {
    if (imageUrl.length === 0) {
      return new MemoryDraftActionResult(false, '请先添加照片');
    }
    try {
      const result = await this.repository.generate(context, imageUrl, capturedAt);
      if (result.code !== 200 || result.data === undefined || result.data.content.trim().length === 0) {
        return new MemoryDraftActionResult(false, result.message || '大模型未返回记忆草稿');
      }
      return new MemoryDraftActionResult(true, result.message, result.data.content.trim());
    } catch (_error) {
      return new MemoryDraftActionResult(false, 'AI 帮写未完成，请重试');
    }
  }
}
