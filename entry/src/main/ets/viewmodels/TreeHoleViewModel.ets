import { TreeHole } from '../models/TreeHole';
import { TreeMember } from '../models/TreeMember';
import { TreeHoleRepository } from '../repositories/TreeHoleRepository';
import { Context } from '@kit.AbilityKit';

export class TreeHoleViewModel {
  private readonly repository: TreeHoleRepository = new TreeHoleRepository();
  async create(context: Context, name: string): Promise<TreeHole | undefined> { if (name.trim().length === 0) return undefined; const result = await this.repository.create(context, name.trim()); return result.data; }
  async join(context: Context, code: string): Promise<TreeHole | undefined> { const result = await this.repository.join(context, code.trim().toUpperCase()); return result.data; }
  async listMine(context: Context): Promise<TreeHole[]> { const result = await this.repository.listMine(context); return result.data === undefined ? [] : result.data; }
  async members(context: Context, treeId: number): Promise<TreeMember[]> { const result = await this.repository.listMembers(context, treeId); return result.data === undefined ? [] : result.data; }
}
