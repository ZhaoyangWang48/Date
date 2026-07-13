import { TreeHole } from '../models/TreeHole';
import { TreeMember } from '../models/TreeMember';
import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { CreateTreeHoleRequestBody, JoinTreeHoleRequestBody } from '../models/ApiRequests';

export class TreeHoleRepository {
  private readonly http: HttpClient = new HttpClient();

  async create(context: Context, name: string): Promise<ApiResult<TreeHole>> {
    return this.toTree(await this.http.post<TreeHole>(ApiConfig.TREE_HOLES, new CreateTreeHoleRequestBody(name), await TokenStorage.getToken(context)));
  }

  async join(context: Context, code: string): Promise<ApiResult<TreeHole>> {
    return this.toTree(await this.http.post<TreeHole>(`${ApiConfig.TREE_HOLES}/join`, new JoinTreeHoleRequestBody(code), await TokenStorage.getToken(context)));
  }

  async listMine(context: Context): Promise<ApiResult<TreeHole[]>> { return this.toTrees(await this.http.get<TreeHole[]>(ApiConfig.TREE_HOLES, await TokenStorage.getToken(context))); }

  async listMembers(context: Context, treeId: number): Promise<ApiResult<TreeMember[]>> { return this.toMembers(await this.http.get<TreeMember[]>(`${ApiConfig.TREE_HOLES}/${treeId}/members`, await TokenStorage.getToken(context))); }

  private toTree(result: ApiResult<TreeHole>): ApiResult<TreeHole> { if (result.data === undefined) return result; const item = result.data; return new ApiResult<TreeHole>(result.code, result.message, new TreeHole(item.id, item.name, item.inviteCode, item.creatorId, item.createdAt)); }
  private toTrees(result: ApiResult<TreeHole[]>): ApiResult<TreeHole[]> { if (result.data === undefined) return result; return new ApiResult<TreeHole[]>(result.code, result.message, result.data.map((item: TreeHole) => new TreeHole(item.id, item.name, item.inviteCode, item.creatorId, item.createdAt))); }
  private toMembers(result: ApiResult<TreeMember[]>): ApiResult<TreeMember[]> { if (result.data === undefined) return result; return new ApiResult<TreeMember[]>(result.code, result.message, result.data.map((item: TreeMember) => new TreeMember(item.id, item.treeHoleId, item.userId, item.nickname, item.role))); }
}
