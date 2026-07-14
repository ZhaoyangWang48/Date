import { Context } from '@kit.AbilityKit';
import { DriftBottle, ResonanceLeaf } from '../models/DriftBottle';
import { DriftBottleRepository } from '../repositories/DriftBottleRepository';

export class DriftActionResult<T> {
  success: boolean = false; message: string = ''; data: T | undefined = undefined;
  constructor(success: boolean, message: string, data?: T) { this.success = success; this.message = message; this.data = data; }
}

export class DriftBottleViewModel {
  private readonly repository: DriftBottleRepository = new DriftBottleRepository();
  async throwBottle(context: Context, memoryId: number, content: string, mood: string): Promise<DriftActionResult<DriftBottle>> { const result = await this.repository.throwBottle(context, memoryId, content.trim(), mood); return new DriftActionResult<DriftBottle>(result.code === 200, result.message, result.data); }
  async pickupBottle(context: Context): Promise<DriftActionResult<DriftBottle>> { const result = await this.repository.pickup(context); return new DriftActionResult<DriftBottle>(result.code === 200, result.message, result.data); }
  async sendResonance(context: Context, bottleId: number, mood: string): Promise<DriftActionResult<ResonanceLeaf>> { const result = await this.repository.resonate(context, bottleId, mood); return new DriftActionResult<ResonanceLeaf>(result.code === 200, result.message, result.data); }
  async listMyBottles(context: Context): Promise<DriftBottle[]> { return (await this.repository.mine(context)).data ?? []; }
  async listMyResonances(context: Context): Promise<ResonanceLeaf[]> { return (await this.repository.resonances(context)).data ?? []; }
  async getTodayPickupCount(context: Context): Promise<number> { return (await this.repository.pickupCount(context)).data?.count ?? 0; }
}
