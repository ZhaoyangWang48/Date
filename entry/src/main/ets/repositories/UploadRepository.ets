import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient, ImageUploadData } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { UploadFileService } from '../services/UploadFileService';

export class UploadRepository {
  private readonly http: HttpClient = new HttpClient();
  private readonly uploadFileService: UploadFileService = new UploadFileService();

  async uploadImage(context: Context, localUri: string): Promise<ApiResult<string>> {
    return this.uploadWithOptions(context, localUri, false, 0, 0, 0, 0);
  }

  async uploadWithOptions(context: Context, localUri: string, optimize: boolean,
    cropX: number, cropY: number, cropW: number, cropH: number): Promise<ApiResult<string>> {
    if (localUri.length === 0) {
      return new ApiResult<string>(400, '未选择图片');
    }

    let token: string;
    try {
      token = await TokenStorage.getToken(context);
    } catch (e) {
      return new ApiResult<string>(0, '读取登录状态失败，请重新登录');
    }
    if (token.length === 0) {
      return new ApiResult<string>(401, '未登录，请先登录');
    }

    let preparedPath: string = '';
    let preparedContentType: string = '';
    let preparedFileName: string = '';
    try {
      const prepared = await this.uploadFileService.prepareImage(context, localUri);
      preparedPath = prepared.path;
      preparedContentType = prepared.contentType;
      preparedFileName = prepared.fileName;
    } catch (prepError) {
      const message: string = (prepError as Error).message;
      return new ApiResult<string>(0, message.length > 0 ? message : '照片处理失败，请重新选择');
    }

    let result: ApiResult<ImageUploadData> = new ApiResult<ImageUploadData>(0, '图片上传未完成');
    try {
      result = await this.http.uploadImageFile(preparedPath, token, preparedContentType, preparedFileName,
        optimize, cropX, cropY, cropW, cropH);
    } catch (uploadError) {
      const message: string = (uploadError as Error).message;
      return new ApiResult<string>(0,
        message.length > 0 ? `图片上传失败：${message}` : '图片上传失败，请重试');
    } finally {
      this.uploadFileService.removeQuietly(preparedPath);
    }

    if (result.code !== 200 || result.data === undefined || result.data.imageUrl.length === 0) {
      return new ApiResult<string>(result.code || 0, result.message || '图片上传失败');
    }

    return new ApiResult<string>(result.code, result.message, result.data.imageUrl);
  }
}
