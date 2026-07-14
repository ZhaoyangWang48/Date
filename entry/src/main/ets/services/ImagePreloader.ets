import { http } from '@kit.NetworkKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { Memory } from '../models/Memory';

export class ImagePreloader {
  private static readonly cache: Map<string, string> = new Map();

  /**
   * 批量下载 Memory 列表中的照片到沙箱，返回新 Memory 数组（本地沙箱路径替换 imageUrl）
   */
  static async preloadPhotos(context: Context, photos: Memory[]): Promise<Memory[]> {
    const resolved: Memory[] = [];
    for (let i = 0; i < photos.length; i++) {
      const m = photos[i];
      const url = m.imageUrl;
      if (!url || url.length === 0) {
        resolved.push(m);
        continue;
      }
      // ArkUI 的 Image 对应用沙箱文件应使用 file URI。裸沙箱路径在部分设备上
      // 只会显示组件外框，必须通过 Core File Kit 转为标准 URI。
      if (url.startsWith('file://')) {
        resolved.push(m);
        continue;
      }
      if (url.startsWith(context.filesDir)) {
        resolved.push(ImagePreloader.cloneWithUrl(m, fileUri.getUriFromPath(url)));
        continue;
      }
      // 检查内存缓存
      const cached = ImagePreloader.cache.get(url);
      if (cached) {
        resolved.push(ImagePreloader.cloneWithUrl(m, cached));
        continue;
      }
      // 下载到沙箱
      const localPath = await ImagePreloader.downloadOne(context, url);
      if (localPath) {
        ImagePreloader.cache.set(url, localPath);
        resolved.push(ImagePreloader.cloneWithUrl(m, localPath));
      } else {
        resolved.push(m); // 下载失败保留原 URL
      }
    }
    return resolved;
  }

  private static cloneWithUrl(m: Memory, url: string): Memory {
    return new Memory(
      m.id, m.authorId, m.authorName, m.content, url,
      m.mood, m.date, m.hour, m.createdAt, m.treeHoleId
    );
  }

  private static async downloadOne(context: Context, url: string): Promise<string | null> {
    let httpRequest: http.HttpRequest | null = null;
    try {
      const lowerUrl = url.toLowerCase();
      const ext = lowerUrl.includes('.png') ? 'png' : (lowerUrl.includes('.webp') ? 'webp' : 'jpg');
      const hash = ImagePreloader.urlHash(url);
      const directory = `${context.filesDir}/photo_cache`;
      try {
        fileIo.mkdirSync(directory);
      } catch (_) {
        // 目录已存在时会抛出异常，继续使用即可。
      }
      const filePath = `${directory}/photo_${hash}.${ext}`;
      // 只有非空缓存才可复用，避免上次下载中断留下空文件后永久白屏。
      try {
        const stat = fileIo.statSync(filePath);
        if (stat.size > 0) {
          return fileUri.getUriFromPath(filePath);
        }
        fileIo.unlinkSync(filePath);
      } catch (_) {
        // 文件不存在，继续下载
      }
      // 下载
      httpRequest = http.createHttp();
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: 10000,
        readTimeout: 10000
      });
      if (response.responseCode === 200) {
        const imageData = response.result as ArrayBuffer;
        if (imageData.byteLength === 0) {
          return null;
        }
        const writeFile: fileIo.File = fileIo.openSync(filePath,
          fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
        try {
          fileIo.writeSync(writeFile.fd, imageData);
        } finally {
          fileIo.closeSync(writeFile);
        }
        return fileUri.getUriFromPath(filePath);
      }
    } catch (e) {
      console.error(`[ImagePreloader] download failed: ${url} ${JSON.stringify(e)}`);
    } finally {
      if (httpRequest) {
        httpRequest.destroy();
      }
    }
    return null;
  }

  private static urlHash(url: string): string {
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      hash = ((hash << 5) - hash) + url.charCodeAt(i);
      hash |= 0;
    }
    return Math.abs(hash).toString(16);
  }
}
