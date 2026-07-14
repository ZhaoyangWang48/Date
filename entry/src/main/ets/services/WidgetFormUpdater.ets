import { Context } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { formBindingData, formInfo, formProvider } from '@kit.FormKit';
import { StoredPhoto, WidgetPhotoCache } from './WidgetPhotoCache';

class WidgetRefreshData {
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

class RefreshPayload {
  data: WidgetRefreshData = new WidgetRefreshData();
  fds: number[] = [];
}

/**
 * 主应用侧的卡片刷新器。
 *
 * DevEco 同版本覆盖安装会重启卡片渲染进程，但系统不一定回调
 * EntryFormAbility.onUpdateForm。memory:// 图片不会跨渲染进程持久化，
 * 因此首页准备好本地照片后主动刷新所有已发布的卡片实例。
 */
export class WidgetFormUpdater {
  private static imageSequence: number = 0;

  static async refreshAll(context: Context): Promise<void> {
    const photos: StoredPhoto[] = WidgetPhotoCache.loadSync(context);
    if (photos.length === 0) return;

    try {
      const forms: formInfo.RunningFormInfo[] = await formProvider.getPublishedRunningFormInfos();
      for (let i = 0; i < forms.length; i++) {
        const form: formInfo.RunningFormInfo = forms[i];
        if (form.formName !== 'RecentPhotoWidget') continue;
        await WidgetFormUpdater.refreshOne(form.formId, photos);
      }
    } catch (error) {
      console.error(`[WidgetUpdater] Refresh all failed: ${JSON.stringify(error)}`);
    }
  }

  private static async refreshOne(formId: string, photos: StoredPhoto[]): Promise<void> {
    const payload: RefreshPayload = WidgetFormUpdater.buildPayload(photos);
    try {
      await formProvider.updateForm(formId,
        formBindingData.createFormBindingData(payload.data));
      console.info(`[WidgetUpdater] Refreshed formId=${formId}, images=${payload.fds.length}`);
    } catch (error) {
      console.error(`[WidgetUpdater] Refresh failed formId=${formId}: ${JSON.stringify(error)}`);
    } finally {
      for (let i = 0; i < payload.fds.length; i++) {
        try {
          fileIo.closeSync(payload.fds[i]);
        } catch (_) {
        }
      }
    }
  }

  private static buildPayload(photos: StoredPhoto[]): RefreshPayload {
    const payload = new RefreshPayload();
    payload.data.photoCount = Math.min(photos.length, 4);
    payload.data.lastUpdate = WidgetFormUpdater.timeNow();
    const imageMap: Record<string, number> = {};
    const slots: string[] = ['photo0', 'photo1', 'photo2', 'photo3'];

    for (let i = 0; i < Math.min(photos.length, 4); i++) {
      const photo: StoredPhoto = photos[i];
      const slot: string = slots[i];
      WidgetFormUpdater.setPhotoDate(payload.data, slot, photo.date);
      if (photo.url.startsWith('http://') || photo.url.startsWith('https://')) continue;

      try {
        const file: fileIo.File = fileIo.openSync(photo.url, fileIo.OpenMode.READ_ONLY);
        WidgetFormUpdater.imageSequence = WidgetFormUpdater.imageSequence + 1;
        const imageKey = `${slot}_${Date.now()}_${WidgetFormUpdater.imageSequence}`;
        imageMap[imageKey] = file.fd;
        payload.fds.push(file.fd);
        WidgetFormUpdater.setPhotoField(payload.data, slot, imageKey);
      } catch (error) {
        console.error(`[WidgetUpdater] Open image failed: ${photo.url} ${JSON.stringify(error)}`);
      }
    }

    payload.data.formImages = imageMap;
    payload.data.hasPhotos = payload.fds.length > 0 ? 1 : 0;
    return payload;
  }

  private static setPhotoField(data: WidgetRefreshData, slot: string, value: string): void {
    switch (slot) {
      case 'photo0': data.photo0 = value; break;
      case 'photo1': data.photo1 = value; break;
      case 'photo2': data.photo2 = value; break;
      case 'photo3': data.photo3 = value; break;
    }
  }

  private static setPhotoDate(data: WidgetRefreshData, slot: string, value: string): void {
    switch (slot) {
      case 'photo0': data.photo0Date = value; break;
      case 'photo1': data.photo1Date = value; break;
      case 'photo2': data.photo2Date = value; break;
      case 'photo3': data.photo3Date = value; break;
    }
  }

  private static timeNow(): string {
    const now = new Date();
    return `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
  }
}
