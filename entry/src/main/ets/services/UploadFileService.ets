import { Context } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { fileIo } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';

export class PreparedUploadFile {
  path: string = '';
  contentType: string = 'image/jpeg';
  fileName: string = 'memory.jpg';

  constructor(path: string, contentType: string, fileName: string) {
    this.path = path;
    this.contentType = contentType;
    this.fileName = fileName;
  }
}

export class UploadFileService {
  async prepareImage(context: Context, sourceUri: string): Promise<PreparedUploadFile> {
    if (sourceUri.length === 0) {
      throw new Error('未选择照片');
    }

    const ts: number = Date.now();
    const destPath: string = `${context.cacheDir}/memory-${ts}.jpg`;
    let stage: string = 'OPEN_URI';
    let sourceFile: fileIo.File | undefined = undefined;
    let outputFile: fileIo.File | undefined = undefined;
    let imageSource: image.ImageSource | undefined;
    let pixelMap: image.PixelMap | undefined;
    let imagePacker: image.ImagePacker | undefined;

    try {
      console.info('[UploadFile] OPEN_URI start');
      // PhotoViewPicker 返回的是带临时授权的媒体 URI，先打开 fd，不把 URI 当作普通路径。
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY);

      stage = 'DECODE_IMAGE';
      imageSource = image.createImageSource(sourceFile.fd);
      const info: image.ImageInfo = await imageSource.getImageInfo();
      console.info(`[UploadFile] ImageKit info: ${info.size.width}x${info.size.height} mime=${info.mimeType}`);

      const maxDim: number = 1600;
      let decodeOpts: image.DecodingOptions = {};
      if (info.size.width > maxDim || info.size.height > maxDim) {
        const scale: number = maxDim / Math.max(info.size.width, info.size.height);
        decodeOpts.desiredSize = {
          width: Math.round(info.size.width * scale),
          height: Math.round(info.size.height * scale)
        };
      }

      pixelMap = await imageSource.createPixelMap(decodeOpts);

      stage = 'ENCODE_JPEG';
      outputFile = fileIo.openSync(destPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      imagePacker = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/jpeg',
        quality: 82
      };
      await imagePacker.packToFile(pixelMap, outputFile.fd, packOpts);
      fileIo.closeSync(outputFile);
      outputFile = undefined;

      stage = 'VERIFY_CACHE';
      const stat: fileIo.Stat = fileIo.statSync(destPath);
      console.info(`[UploadFile] written: ${stat.size} bytes to ${destPath}`);
      if (stat.size === 0) {
        throw new Error('编码后文件为空');
      }

      return new PreparedUploadFile(destPath, 'image/jpeg', `memory-${ts}.jpg`);
    } catch (error) {
      this.removeQuietly(destPath);
      const code: number = (error as BusinessError).code;
      const detail: string = (error as Error).message;
      console.error(`[UploadFile] ${stage} failed code=${code} message=${detail}`);
      throw new Error(`照片处理失败（${stage}，错误码 ${code}）`);
    } finally {
      if (imagePacker !== undefined) {
        try { await imagePacker.release(); } catch (_error) { }
      }
      if (pixelMap !== undefined) {
        try { await pixelMap.release(); } catch (_error) { }
      }
      if (imageSource !== undefined) {
        try { await imageSource.release(); } catch (_error) { }
      }
      if (outputFile !== undefined) {
        try { fileIo.closeSync(outputFile); } catch (_error) { }
      }
      if (sourceFile !== undefined) {
        try { fileIo.closeSync(sourceFile); } catch (_error) { }
      }
    }
  }

  removeQuietly(path: string): void {
    if (path.length === 0) {
      return;
    }
    try {
      fileIo.unlinkSync(path);
    } catch (_error) {
    }
  }
}
