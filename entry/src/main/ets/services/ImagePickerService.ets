import { photoAccessHelper } from '@kit.MediaLibraryKit';

export class ImagePickerService {
  async pickOneImage(): Promise<string> {
    try {
      const picker = new photoAccessHelper.PhotoViewPicker();
      const options = new photoAccessHelper.PhotoSelectOptions();
      options.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE;
      options.maxSelectNumber = 1;
      const result = await picker.select(options);
      return result.photoUris.length > 0 ? result.photoUris[0] : '';
    } catch (error) {
      return '';
    }
  }
}
