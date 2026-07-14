import { Context } from '@kit.AbilityKit';
import { TimeCapsule } from '../models/TimeCapsule';
import { TimeCapsuleRepository } from '../repositories/TimeCapsuleRepository';

export class CapsuleActionResult {
  success: boolean = false; message: string = ''; capsule: TimeCapsule | undefined = undefined;
  constructor(success: boolean, message: string, capsule?: TimeCapsule) { this.success = success; this.message = message; this.capsule = capsule; }
}

export class TimeCapsuleViewModel {
  private readonly repository: TimeCapsuleRepository = new TimeCapsuleRepository();
  async list(context: Context): Promise<TimeCapsule[]> { const result = await this.repository.list(context); return result.data ?? []; }
  async get(context: Context, id: number): Promise<TimeCapsule | undefined> { return (await this.repository.get(context, id)).data; }
  async create(context: Context, content: string, mood: string, openAt: string): Promise<CapsuleActionResult> {
    if (content.trim().length === 0) return new CapsuleActionResult(false, '请写下想留给未来的文字');
    const result = await this.repository.create(context, content.trim(), mood, openAt);
    return new CapsuleActionResult(result.code === 200, result.message, result.data);
  }
  async open(context: Context, id: number): Promise<CapsuleActionResult> { const result = await this.repository.open(context, id); return new CapsuleActionResult(result.code === 200, result.message, result.data); }
}
