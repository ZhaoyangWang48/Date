import { preferences } from '@kit.ArkData';
import { fileIo } from '@kit.CoreFileKit';
import { Context } from '@kit.AbilityKit';
import { Memory } from '../models/Memory';
import { ImagePreloader } from './ImagePreloader';

export class StoredPhoto {
  url: string = '';
  date: string = '';

  constructor(url: string, date: string) {
    this.url = url;
    this.date = date;
  }
}

export class WidgetPhotoCache {
  private static readonly STORE_NAME: string = 'zhiyi_widget';
  private static readonly PHOTOS_KEY: string = 'recent_photos';
  private static readonly SYNC_FILE_NAME: string = 'widget_photos.json';

  /**
   * 获取同步缓存文件的路径。
   * 使用 filesDir，主 App 和 FormExtension 可访问同一沙箱，且不会因缓存回收丢失。
   */
  static getSyncFilePath(context: Context): string {
    return `${context.filesDir}/${WidgetPhotoCache.SYNC_FILE_NAME}`;
  }

  /**
   * 同步写入 JSON 文件（供 onAddForm 直接读取）。
   */
  static saveSync(context: Context, photos: StoredPhoto[]): void {
    try {
      const path = WidgetPhotoCache.getSyncFilePath(context);
      const json = JSON.stringify(photos);
      const file: fileIo.File = fileIo.openSync(path,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, json);
      fileIo.closeSync(file);
      console.info(`[WidgetCache] Sync saved ${photos.length} photos → ${path}`);
    } catch (err) {
      console.error(`[WidgetCache] Sync save failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 同步读取 JSON 文件。
   * EntryFormAbility.onAddForm 调用（同步方法内可用）。
   */
  static loadSync(context: Context): StoredPhoto[] {
    try {
      const path = WidgetPhotoCache.getSyncFilePath(context);
      try {
        // fileIo.accessSync 成功时没有返回值，文件不存在时会抛出异常。
        fileIo.accessSync(path);
      } catch (_) {
        console.info('[WidgetCache] Sync file not found');
        return [];
      }
      const file: fileIo.File = fileIo.openSync(path, fileIo.OpenMode.READ_ONLY);
      const stat = fileIo.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fileIo.readSync(file.fd, buf);
      fileIo.closeSync(file);
      const text = String.fromCharCode(...new Uint8Array(buf));
      const photos: StoredPhoto[] = JSON.parse(text) as StoredPhoto[];
      console.info(`[WidgetCache] Sync loaded ${photos.length} photos`);
      return photos;
    } catch (err) {
      console.error(`[WidgetCache] Sync load failed: ${JSON.stringify(err)}`);
      return [];
    }
  }

  // ========== Async（保留给 onFormVisible / onUpdateForm 使用）==========

  static async saveFromMemories(context: Context, memories: Memory[]): Promise<void> {
    const recentMemories: Memory[] = memories
      .filter((m: Memory) => m.imageUrl && m.imageUrl.length > 0)
      .sort((a: Memory, b: Memory) => b.createdAt.localeCompare(a.createdAt))
      .slice(0, 4);

    // 卡片首次创建时 onAddForm 必须同步返回，不能在此阶段等待网络下载。
    // 因此写缓存前统一把网络图片预下载到应用沙箱，缓存中只保存可同步打开的 file URI。
    const localMemories: Memory[] = await ImagePreloader.preloadPhotos(context, recentMemories);
    const photos: StoredPhoto[] = localMemories
      .map((m: Memory) => new StoredPhoto(m.imageUrl, m.date));

    // 同步写文件（关键：onAddForm 靠这个拿数据）
    WidgetPhotoCache.saveSync(context, photos);

    // 同时写 preferences（保留给异步加载使用）
    const json: string = JSON.stringify(photos);
    try {
      const store = await preferences.getPreferences(context, WidgetPhotoCache.STORE_NAME);
      await store.put(WidgetPhotoCache.PHOTOS_KEY, json);
      await store.flush();
    } catch (err) {
      console.error(`[WidgetCache] Save failed: ${JSON.stringify(err)}`);
    }
  }

  static async load(context: Context): Promise<StoredPhoto[]> {
    // 优先读同步文件（更快更可靠）
    const syncPhotos = WidgetPhotoCache.loadSync(context);
    if (syncPhotos.length > 0) {
      return syncPhotos;
    }
    // 回退到 preferences
    try {
      const store = await preferences.getPreferences(context, WidgetPhotoCache.STORE_NAME);
      const json: string = await store.get(WidgetPhotoCache.PHOTOS_KEY, '') as string;
      if (!json) return [];
      return JSON.parse(json) as StoredPhoto[];
    } catch (err) {
      return [];
    }
  }
}
