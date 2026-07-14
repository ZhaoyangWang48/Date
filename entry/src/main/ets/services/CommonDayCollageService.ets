import { Context } from '@kit.AbilityKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { image } from '@kit.ImageKit';
import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { Memory } from '../models/Memory';
import { ImagePreloader } from './ImagePreloader';

export class CollageExportResult {
  success: boolean = false;
  message: string = '';

  constructor(success: boolean, message: string) {
    this.success = success;
    this.message = message;
  }
}

export class CommonDayCollageService {
  private static readonly CELL_SIZE: number = 720;
  private static readonly BYTES_PER_PIXEL: number = 4;

  async export(context: Context, photos: Memory[], date: string, hour: number): Promise<CollageExportResult> {
    if (photos.length < 2 || photos.length > 4) {
      return new CollageExportResult(false, '仅支持 2–4 人的共同一天图片导出');
    }

    let outputPath: string = '';
    let outputPixelMap: image.PixelMap | undefined = undefined;
    let packer: image.ImagePacker | undefined = undefined;
    let outputFile: fileIo.File | undefined = undefined;
    let albumSourceFile: fileIo.File | undefined = undefined;
    let albumDestinationFile: fileIo.File | undefined = undefined;
    try {
      const localPhotos: Memory[] = await ImagePreloader.preloadPhotos(context, photos);
      const canvasWidth: number = photos.length === 4 ?
        CommonDayCollageService.CELL_SIZE * 2 : CommonDayCollageService.CELL_SIZE * photos.length;
      const canvasHeight: number = photos.length === 4 ?
        CommonDayCollageService.CELL_SIZE * 2 : CommonDayCollageService.CELL_SIZE;
      const canvas: Uint8Array = new Uint8Array(canvasWidth * canvasHeight *
        CommonDayCollageService.BYTES_PER_PIXEL);

      // 使用白色底色，避免 JPEG 对透明区域的处理在不同设备上出现黑边。
      for (let i: number = 0; i < canvas.length; i += CommonDayCollageService.BYTES_PER_PIXEL) {
        canvas[i] = 255;
        canvas[i + 1] = 255;
        canvas[i + 2] = 255;
        canvas[i + 3] = 255;
      }

      for (let index: number = 0; index < localPhotos.length; index++) {
        const cell: Uint8Array = await this.decodeSquare(localPhotos[index].imageUrl);
        const position = this.positionFor(index, photos.length);
        this.copyCell(canvas, canvasWidth, cell, position[0], position[1]);
      }

      const options: image.InitializationOptions = {
        size: { width: canvasWidth, height: canvasHeight },
        srcPixelFormat: image.PixelMapFormat.RGBA_8888,
        pixelFormat: image.PixelMapFormat.RGBA_8888,
        editable: false
      };
      outputPixelMap = await image.createPixelMap(canvas.buffer, options);
      outputPath = `${context.cacheDir}/common-day-${date}-${this.pad(hour)}-${Date.now()}.jpg`;
      outputFile = fileIo.openSync(outputPath,
        fileIo.OpenMode.CREATE | fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.TRUNC);
      packer = image.createImagePacker();
      await packer.packToFile(outputPixelMap, outputFile.fd, {
        format: 'image/jpeg',
        quality: 92
      });
      fileIo.closeSync(outputFile);
      outputFile = undefined;

      const helper: photoAccessHelper.PhotoAccessHelper = photoAccessHelper.getPhotoAccessHelper(context);
      const config: photoAccessHelper.PhotoCreationConfig = {
        title: `共同一天-${date}-${this.pad(hour)}时`,
        fileNameExtension: 'jpg',
        photoType: photoAccessHelper.PhotoType.IMAGE
      };
      const savedUris: string[] = await helper.showAssetsCreationDialog(
        [fileUri.getUriFromPath(outputPath)], [config]);
      if (savedUris.length === 0) {
        return new CollageExportResult(false, '已取消保存');
      }

      // 保存对话框只负责创建并授权媒体库目标 URI，不会自动复制图片内容。
      // 必须把沙箱中的 JPEG 写入目标 URI，完成后才能向用户报告导出成功。
      const sourceSize: number = fileIo.statSync(outputPath).size;
      albumSourceFile = fileIo.openSync(outputPath, fileIo.OpenMode.READ_ONLY);
      albumDestinationFile = fileIo.openSync(savedUris[0], fileIo.OpenMode.WRITE_ONLY);
      await fileIo.copyFile(albumSourceFile.fd, albumDestinationFile.fd);
      const destinationSize: number = fileIo.statSync(albumDestinationFile.fd).size;
      if (sourceSize <= 0 || destinationSize !== sourceSize) {
        throw new Error(`album copy incomplete: source=${sourceSize}, destination=${destinationSize}`);
      }
      fileIo.closeSync(albumSourceFile);
      albumSourceFile = undefined;
      fileIo.closeSync(albumDestinationFile);
      albumDestinationFile = undefined;
      return new CollageExportResult(true, '拼图已保存到相册');
    } catch (error) {
      console.error(`[CommonDayCollage] export failed: ${JSON.stringify(error)}`);
      return new CollageExportResult(false, '图片合成或保存失败，请检查网络后重试');
    } finally {
      if (albumSourceFile !== undefined) {
        try { fileIo.closeSync(albumSourceFile); } catch (_error) { }
      }
      if (albumDestinationFile !== undefined) {
        try { fileIo.closeSync(albumDestinationFile); } catch (_error) { }
      }
      if (outputFile !== undefined) {
        try { fileIo.closeSync(outputFile); } catch (_error) { }
      }
      if (packer !== undefined) {
        try { await packer.release(); } catch (_error) { }
      }
      if (outputPixelMap !== undefined) {
        try { await outputPixelMap.release(); } catch (_error) { }
      }
      if (outputPath.length > 0) {
        try { fileIo.unlinkSync(outputPath); } catch (_error) { }
      }
    }
  }

  private async decodeSquare(uri: string): Promise<Uint8Array> {
    let sourceFile: fileIo.File | undefined = undefined;
    let source: image.ImageSource | undefined = undefined;
    let pixelMap: image.PixelMap | undefined = undefined;
    try {
      sourceFile = fileIo.openSync(uri, fileIo.OpenMode.READ_ONLY);
      source = image.createImageSource(sourceFile.fd);
      const info: image.ImageInfo = await source.getImageInfo();
      const side: number = Math.min(info.size.width, info.size.height);
      const region: image.Region = {
        x: Math.floor((info.size.width - side) / 2),
        y: Math.floor((info.size.height - side) / 2),
        size: { width: side, height: side }
      };
      pixelMap = await source.createPixelMap({
        desiredRegion: region,
        desiredSize: {
          width: CommonDayCollageService.CELL_SIZE,
          height: CommonDayCollageService.CELL_SIZE
        },
        desiredPixelFormat: image.PixelMapFormat.RGBA_8888,
        cropAndScaleStrategy: image.CropAndScaleStrategy.CROP_FIRST
      });

      const rowBytes: number = pixelMap.getBytesNumberPerRow();
      const buffer: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
      await pixelMap.readPixelsToBuffer(buffer);
      const sourceBytes: Uint8Array = new Uint8Array(buffer);
      const packedRowBytes: number = CommonDayCollageService.CELL_SIZE *
        CommonDayCollageService.BYTES_PER_PIXEL;
      if (rowBytes === packedRowBytes) return sourceBytes;

      const packed: Uint8Array = new Uint8Array(packedRowBytes * CommonDayCollageService.CELL_SIZE);
      for (let row: number = 0; row < CommonDayCollageService.CELL_SIZE; row++) {
        const sourceOffset: number = row * rowBytes;
        packed.set(sourceBytes.subarray(sourceOffset, sourceOffset + packedRowBytes), row * packedRowBytes);
      }
      return packed;
    } finally {
      if (pixelMap !== undefined) {
        try { await pixelMap.release(); } catch (_error) { }
      }
      if (source !== undefined) {
        try { await source.release(); } catch (_error) { }
      }
      if (sourceFile !== undefined) {
        try { fileIo.closeSync(sourceFile); } catch (_error) { }
      }
    }
  }

  private copyCell(canvas: Uint8Array, canvasWidth: number, cell: Uint8Array,
    cellX: number, cellY: number): void {
    const rowBytes: number = CommonDayCollageService.CELL_SIZE * CommonDayCollageService.BYTES_PER_PIXEL;
    for (let row: number = 0; row < CommonDayCollageService.CELL_SIZE; row++) {
      const sourceOffset: number = row * rowBytes;
      const targetOffset: number = ((cellY + row) * canvasWidth + cellX) *
        CommonDayCollageService.BYTES_PER_PIXEL;
      canvas.set(cell.subarray(sourceOffset, sourceOffset + rowBytes), targetOffset);
    }
  }

  private positionFor(index: number, count: number): number[] {
    if (count < 4) {
      return [index * CommonDayCollageService.CELL_SIZE, 0];
    }
    // 四人时按成员顺序依次放置：左上、左下、右上、右下。
    return [index < 2 ? 0 : CommonDayCollageService.CELL_SIZE,
      index % 2 === 0 ? 0 : CommonDayCollageService.CELL_SIZE];
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }
}
