import { Memory } from '../models/Memory';
import { MemoryRepository } from '../repositories/MemoryRepository';
import { UploadRepository } from '../repositories/UploadRepository';
import { Context } from '@kit.AbilityKit';

export class MemoryActionResult {
  success: boolean = false;
  message: string = '';
  memory: Memory | undefined = undefined;

  constructor(success: boolean, message: string, memory?: Memory) {
    this.success = success;
    this.message = message;
    this.memory = memory;
  }
}

export class MemoryViewModel {
  private readonly memoryRepository: MemoryRepository = new MemoryRepository();
  private readonly uploadRepository: UploadRepository = new UploadRepository();

  async createMemory(context: Context, content: string, imageUri: string, mood: string,
    treeHoleId: number = 0): Promise<MemoryActionResult> {
    const now = new Date();
    const date = `${now.getFullYear()}-${this.pad(now.getMonth() + 1)}-${this.pad(now.getDate())}`;
    return this.createMemoryAt(context, content, imageUri, mood, date, now.getHours(), treeHoleId);
  }

  async createMemoryAt(context: Context, content: string, imageUri: string, mood: string, date: string,
    hour: number, treeHoleId: number = 0): Promise<MemoryActionResult> {
    const text = content.trim();
    if (text.length === 0 && imageUri.length === 0) {
      return new MemoryActionResult(false, '请写下一段记忆，或选择一张图片');
    }

    let imageUrl = '';
    if (imageUri.length > 0) {
      const uploaded = await this.uploadRepository.uploadImage(context, imageUri);
      if (uploaded.code !== 200 || uploaded.data === undefined) {
        return new MemoryActionResult(false, uploaded.message);
      }
      imageUrl = uploaded.data;
    }

    const created = await this.memoryRepository.create(context, text, imageUrl, mood, date, hour, treeHoleId);
    if (created.code !== 200 || created.data === undefined) return new MemoryActionResult(false, created.message);
    return new MemoryActionResult(true, created.message, created.data);
  }

  async listMemories(context: Context): Promise<Memory[]> {
    const result = await this.memoryRepository.list(context);
    return result.data === undefined ? [] : result.data;
  }

  async getMemory(context: Context, memoryId: number): Promise<Memory | undefined> {
    const result = await this.memoryRepository.getById(context, memoryId);
    return result.data;
  }

  async listTreeHoleMemories(context: Context, treeHoleId: number): Promise<Memory[]> {
    const result = await this.memoryRepository.listByTreeHole(context, treeHoleId);
    return result.data === undefined ? [] : result.data;
  }

  async listDateMemories(context: Context, treeHoleId: number, date: string): Promise<Memory[]> {
    const result = await this.memoryRepository.listByDate(context, treeHoleId, date);
    return result.data === undefined ? [] : result.data;
  }

  async deleteMemory(context: Context, memoryId: number): Promise<MemoryActionResult> {
    const result = await this.memoryRepository.delete(context, memoryId);
    return new MemoryActionResult(result.code === 200, result.message);
  }

  async createMemoryWithImage(context: Context, content: string, imageUri: string, mood: string,
    optimize: boolean, cropX: number, cropY: number, cropW: number, cropH: number,
    treeHoleId: number = 0): Promise<MemoryActionResult> {
    const now = new Date();
    const date = `${now.getFullYear()}-${this.pad(now.getMonth() + 1)}-${this.pad(now.getDate())}`;
    const text = content.trim();
    if (text.length === 0 && imageUri.length === 0) {
      return new MemoryActionResult(false, '请写下一段记忆，或选择一张图片');
    }
    let imageUrl = '';
    if (imageUri.length > 0) {
      const uploaded = await this.uploadRepository.uploadWithOptions(context, imageUri,
        optimize, cropX, cropY, cropW, cropH);
      if (uploaded.code !== 200 || uploaded.data === undefined) {
        return new MemoryActionResult(false, uploaded.message);
      }
      imageUrl = uploaded.data;
    }
    const created = await this.memoryRepository.create(context, text, imageUrl, mood, date, now.getHours(), treeHoleId);
    if (created.code !== 200 || created.data === undefined) return new MemoryActionResult(false, created.message);
    return new MemoryActionResult(true, created.message, created.data);
  }

  async createWithUrl(context: Context, content: string, imageUrl: string, mood: string,
    date: string, hour: number, treeHoleId: number = 0): Promise<MemoryActionResult> {
    const text = content.trim();
    if (text.length === 0 && imageUrl.length === 0)
      return new MemoryActionResult(false, '请写下一段记忆，或选择一张图片');
    const created = await this.memoryRepository.create(context, text, imageUrl, mood, date, hour, treeHoleId);
    if (created.code !== 200 || created.data === undefined) return new MemoryActionResult(false, created.message);
    return new MemoryActionResult(true, created.message, created.data);
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }
}
