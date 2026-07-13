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

  private async downloadImage(url: string, key: string): Promise<DownloadResult | null> {
    let httpRequest: http.HttpRequest | null = null;
    try {
      const ext = url.includes('.png') ? 'png' : 'jpg';
      const filePath = `${this.context.cacheDir}/widget_${key}.${ext}`;
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
      const file: fileIo.File = fileIo.openSync(filePath, fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY);
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
      const key: string = keys[i];
      const photo: StoredPhoto = photos[i];
      if (photo.url.length > 0) {
        const result: DownloadResult | null = await this.downloadImage(photo.url, key);
        if (result && result.fd >= 0) {
          imageMap[result.path] = result.fd;
          this.setPhotoField(data, key, result.path);
        }
      }
      this.setPhotoDate(data, key, photo.date);
    }

    data.formImages = imageMap;
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
        if (result.code === 0 && result.data) {
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
    formProvider.updateForm(formId, formBindingData.createFormBindingData(widgetData));

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
    // 同步加载缓存数据（onAddForm 必须同步返回）
    const photos: StoredPhoto[] = WidgetPhotoCache.loadSync(this.context);
    if (photos.length > 0) {
      const data = new PhotoWidgetData();
      data.photoCount = photos.length;
      data.hasPhotos = 1;
      data.lastUpdate = this.timeNow();
      if (photos.length > 0 && photos[0]) { data.photo0 = photos[0].url; data.photo0Date = photos[0].date; }
      if (photos.length > 1 && photos[1]) { data.photo1 = photos[1].url; data.photo1Date = photos[1].date; }
      if (photos.length > 2 && photos[2]) { data.photo2 = photos[2].url; data.photo2Date = photos[2].date; }
      if (photos.length > 3 && photos[3]) { data.photo3 = photos[3].url; data.photo3Date = photos[3].date; }
      console.info(`[Form] onAddForm: loaded ${photos.length} photos from cache`);
      return formBindingData.createFormBindingData(data);
    }
    console.info('[Form] onAddForm: no cache, returning empty');
    return formBindingData.createFormBindingData(new PhotoWidgetData());
  }

  onFormVisible(formId: string): void {
    console.info(`[Form] onFormVisible: formId=${formId}`);
    this.loadWidgetData(formId);
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
    console.info('[Form] onDestroy');
  }
}
