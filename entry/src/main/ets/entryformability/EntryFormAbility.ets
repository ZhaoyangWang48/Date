import { FormExtensionAbility, formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { http } from '@kit.NetworkKit';
import { fileIo } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { MemoryRepository } from '../repositories/MemoryRepository';
import { Memory } from '../models/Memory';
import { WidgetPhotoCache, StoredPhoto } from '../services/WidgetPhotoCache';

class DownloadResult {
  path: string = '';
  fd: number = -1;
}

class PhotoWidgetData {
  photoCount: number = 0;
  photo0: string = '';
  photo0Date: string = '';
  photo1: string = '';
  photo1Date: string = '';
  photo2: string = '';
  photo2Date: string = '';
  photo3: string = '';
  photo3Date: string = '';
  hasPhotos: number = 0;
  lastUpdate: string = '';
  formImages?: Record<string, number> = {};
}

export default class EntryFormAbility extends FormExtensionAbility {
  private readonly memoryRepository: MemoryRepository = new MemoryRepository();
  private readonly retainedFormFds: number[] = [];
  private imageSequence: number = 0;

  private nextImageKey(slot: string): string {
    this.imageSequence = this.imageSequence + 1;
    return `${slot}_${Date.now()}_${this.imageSequence}`;
  }

  private openLocalImage(source: string): DownloadResult | null {
    try {
      const file: fileIo.File = fileIo.openSync(source, fileIo.OpenMode.READ_ONLY);
      const result = new DownloadResult();
      result.path = source;
      result.fd = file.fd;
      return result;
    } catch (err) {
      console.error(`[Form] Open local image failed: ${source} ${JSON.stringify(err)}`);
      return null;
    }
  }

  private async downloadImage(url: string, key: string): Promise<DownloadResult | null> {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return this.openLocalImage(url);
    }
    let httpRequest: http.HttpRequest | null = null;
    try {
      const ext = url.includes('.png') ? 'png' : 'jpg';
      const directory = `${this.context.filesDir}/widget_photos`;
      try {
        fileIo.mkdirSync(directory);
      } catch (_) {
        // 文件夹已存在时继续使用。
      }
      const filePath = `${directory}/widget_${key}.${ext}`;
      httpRequest = http.createHttp();
      const response: http.HttpResponse = await httpRequest.request(url, {
        method: http.RequestMethod.GET,
        connectTimeout: 8000,
        readTimeout: 15000,
        expectDataType: http.HttpDataType.ARRAY_BUFFER
      });
      if (response.responseCode !== 200 || !response.result) {
        console.error(`[Form] Download failed: ${url} status=${response.responseCode}`);
        return null;
      }
      const arrayBuffer: ArrayBuffer = response.result as ArrayBuffer;
      const file: fileIo.File = fileIo.openSync(filePath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC | fileIo.OpenMode.WRITE_ONLY);
      fileIo.writeSync(file.fd, arrayBuffer);
      fileIo.closeSync(file);
      const readFile: fileIo.File = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY);
      console.info(`[Form] Downloaded: ${url} → ${filePath} fd=${readFile.fd}`);
      const result = new DownloadResult();
      result.path = filePath;
      result.fd = readFile.fd;
      return result;
    } catch (err) {
      console.error(`[Form] Download error: ${url} → ${JSON.stringify(err)}`);
      return null;
    } finally {
      if (httpRequest) {
        httpRequest.destroy();
      }
    }
  }

  private async buildWithImages(photos: StoredPhoto[]): Promise<PhotoWidgetData> {
    const data = new PhotoWidgetData();
    data.photoCount = photos.length;
    data.hasPhotos = photos.length > 0 ? 1 : 0;
    data.lastUpdate = this.timeNow();
    const imageMap: Record<string, number> = {};

    const keys: string[] = ['photo0', 'photo1', 'photo2', 'photo3'];
    for (let i = 0; i < Math.min(photos.length, 4); i++) {
      const slot: string = keys[i];
      const photo: StoredPhoto = photos[i];
      if (photo.url.length > 0) {
        const result: DownloadResult | null = await this.downloadImage(photo.url, slot);
        if (result && result.fd >= 0) {
          // 每次更新都换一个逻辑图片名，强制卡片渲染进程重新读取 fd。
          const imageKey: string = this.nextImageKey(slot);
          imageMap[imageKey] = result.fd;
          this.setPhotoField(data, slot, imageKey);
        }
      }
      this.setPhotoDate(data, slot, photo.date);
    }

    data.formImages = imageMap;
    data.hasPhotos = Object.keys(imageMap).length > 0 ? 1 : 0;
    return data;
  }

  private closeFormImages(data: PhotoWidgetData): void {
    if (!data.formImages) return;
    const keys = Object.keys(data.formImages);
    for (let i = 0; i < keys.length; i++) {
      try {
        fileIo.closeSync(data.formImages[keys[i]]);
      } catch (_) {
      }
    }
  }

  private buildCachedData(photos: StoredPhoto[]): PhotoWidgetData {
    const data = new PhotoWidgetData();
    data.photoCount = photos.length;
    data.lastUpdate = this.timeNow();
    const imageMap: Record<string, number> = {};
    const keys: string[] = ['photo0', 'photo1', 'photo2', 'photo3'];
    for (let i = 0; i < Math.min(photos.length, 4); i++) {
      const photo = photos[i];
      const slot = keys[i];
      this.setPhotoDate(data, slot, photo.date);
      if (photo.url.startsWith('http://') || photo.url.startsWith('https://')) continue;
      const result = this.openLocalImage(photo.url);
      if (result && result.fd >= 0) {
        const imageKey: string = this.nextImageKey(slot);
        imageMap[imageKey] = result.fd;
        this.retainedFormFds.push(result.fd);
        this.setPhotoField(data, slot, imageKey);
      }
    }
    data.formImages = imageMap;
    data.hasPhotos = Object.keys(imageMap).length > 0 ? 1 : 0;
    return data;
  }

  private setPhotoField(data: PhotoWidgetData, key: string, value: string): void {
    switch (key) {
      case 'photo0': data.photo0 = value; break;
      case 'photo1': data.photo1 = value; break;
      case 'photo2': data.photo2 = value; break;
      case 'photo3': data.photo3 = value; break;
    }
  }

  private setPhotoDate(data: PhotoWidgetData, key: string, value: string): void {
    switch (key) {
      case 'photo0': data.photo0Date = value; break;
      case 'photo1': data.photo1Date = value; break;
      case 'photo2': data.photo2Date = value; break;
      case 'photo3': data.photo3Date = value; break;
    }
  }

  private async loadWidgetData(formId: string): Promise<void> {
    console.info(`[Form] === loadWidgetData START formId=${formId} ===`);
    try {

    let photos: StoredPhoto[] = [];
    try {
      photos = await WidgetPhotoCache.load(this.context);
      console.info(`[Form] Cache: ${photos.length} photos`);
    } catch (err) {
      console.error(`[Form] Cache error: ${JSON.stringify(err)}`);
    }

    if (photos.length === 0) {
      try {
        const result = await this.memoryRepository.list(this.context);
        console.info(`[Form] API: code=${result.code}`);
        if (result.code === 200 && result.data) {
          const allMemories: Memory[] = result.data;
          const photoMemories: Memory[] = [];
          for (let j = 0; j < allMemories.length; j++) {
            const m = allMemories[j];
            if (m.imageUrl && m.imageUrl.length > 0) {
              photoMemories.push(m);
            }
          }
          photoMemories.sort((a: Memory, b: Memory) => b.createdAt.localeCompare(a.createdAt));
          const top4 = photoMemories.slice(0, 4);
          const newPhotos: StoredPhoto[] = [];
          for (let k = 0; k < top4.length; k++) {
            newPhotos.push(new StoredPhoto(top4[k].imageUrl, top4[k].date));
          }
          photos = newPhotos;
          WidgetPhotoCache.saveFromMemories(this.context, photoMemories);
        }
      } catch (err) {
        console.error(`[Form] API error: ${JSON.stringify(err)}`);
      }
    }

    const widgetData: PhotoWidgetData = await this.buildWithImages(photos);
    const imgCount = widgetData.formImages ? Object.keys(widgetData.formImages).length : 0;
    console.info(`[Form] Updating widget: count=${widgetData.photoCount} images=${imgCount}`);
    try {
      await formProvider.updateForm(formId, formBindingData.createFormBindingData(widgetData));
    } finally {
      this.closeFormImages(widgetData);
    }

    } catch (e) {
      console.error(`[Form] loadWidgetData FATAL: ${JSON.stringify(e)}`);
    }
  }

  private timeNow(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  }

  // ========== 生命周期 ==========

  onAddForm(want: Want): formBindingData.FormBindingData {
    console.info('[Form] onAddForm');
    // 同步返回缓存后再异步刷新一次：兼容首次安装、旧版 HTTP 缓存和卡片选择页预览。
    const rawFormId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY];
    const formId: string = rawFormId === undefined ? '' : `${rawFormId}`;
    if (formId.length > 0) {
      setTimeout(() => { this.loadWidgetData(formId); }, 100);
    }
    // 同步加载缓存数据（onAddForm 必须同步返回）
    const photos: StoredPhoto[] = WidgetPhotoCache.loadSync(this.context);
    if (photos.length > 0) {
      const data = this.buildCachedData(photos);
      console.info(`[Form] onAddForm: loaded ${photos.length} photos from cache`);
      return formBindingData.createFormBindingData(data);
    }
    console.info('[Form] onAddForm: no cache, returning empty');
    return formBindingData.createFormBindingData(new PhotoWidgetData());
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    Object.keys(newStatus).forEach((formId: string) => {
      if (newStatus[formId] === formInfo.VisibilityType.FORM_VISIBLE) {
        console.info(`[Form] onChangeFormVisibility: visible formId=${formId}`);
        this.loadWidgetData(formId);
      }
    });
  }

  onUpdateForm(formId: string, want?: Want): void {
    console.info(`[Form] onUpdateForm: formId=${formId}`);
    this.loadWidgetData(formId);
  }

  onFormEvent(formId: string, message: string): void {
    console.info(`[Form] onFormEvent: formId=${formId}`);
  }

  onAcquireFormState(want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }

  onRemoveForm(formId: string): void {
    console.info(`[Form] onRemoveForm: formId=${formId}`);
  }

  onDestroy(): void {
    for (let i = 0; i < this.retainedFormFds.length; i++) {
      try {
        fileIo.closeSync(this.retainedFormFds[i]);
      } catch (_) {
      }
    }
    this.retainedFormFds.length = 0;
    console.info('[Form] onDestroy');
  }
}
