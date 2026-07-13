import { ApiConfig } from '../constants/ApiConfig';

const MIN_SIZE = 40;
const HANDLE_SIZE = 22;

@Component
export struct CropOverlay {
  @Prop imageUri: string = '';
  @Prop bare: boolean = false;
  @State cropX: number = 0.1;
  @State cropY: number = 0.2;
  @State cropW: number = 0.8;
  @State cropH: number = 0.6;
  @State cw: number = 360;
  @State ch: number = 500;
  @State private imgW: number = 0;
  @State private imgH: number = 0;
  onCropChange: (x: number, y: number, w: number, h: number) => void = (_x, _y, _w, _h) => {};
  onConfirm: (x: number, y: number, w: number, h: number) => void = (_x, _y, _w, _h) => {};
  onCancel: () => void = () => {};

  private startX: number = 0; private startY: number = 0;
  private rsX: number = 0; private rsY: number = 0;
  private rsW: number = 0; private rsH: number = 0;

  private pxX(): number { return this.cropX * this.cw; }
  private pxY(): number { return this.cropY * this.ch; }
  private pxW(): number { return this.cropW * this.cw; }
  private pxH(): number { return this.cropH * this.ch; }

  private getCorrected(): number[] {
    if (this.imgW <= 0 || this.imgH <= 0 || this.cw <= 0 || this.ch <= 0) {
      return [this.cropX, this.cropY, this.cropW, this.cropH];
    }
    const scaleW = this.cw / this.imgW;
    const scaleH = this.ch / this.imgH;
    const scale = Math.min(scaleW, scaleH);
    const dispW = this.imgW * scale;
    const dispH = this.imgH * scale;
    const padX = (this.cw - dispW) / 2;
    const padY = (this.ch - dispH) / 2;
    const stackX = this.cropX * this.cw;
    const stackY = this.cropY * this.ch;
    const stackR = stackX + this.cropW * this.cw;
    const stackB = stackY + this.cropH * this.ch;
    const imgL = Math.max(stackX, padX);
    const imgT = Math.max(stackY, padY);
    const imgR = Math.min(stackR, padX + dispW);
    const imgB = Math.min(stackB, padY + dispH);
    const iw = Math.max(0, imgR - imgL);
    const ih = Math.max(0, imgB - imgT);
    const cfX = iw > 0 ? (imgL - padX) / dispW : 0;
    const cfY = ih > 0 ? (imgT - padY) / dispH : 0;
    const cfW = iw > 0 ? iw / dispW : 0;
    const cfH = ih > 0 ? ih / dispH : 0;
    return [cfX, cfY, cfW, cfH];
  }

  private notify(): void {
    const r = this.getCorrected();
    this.onCropChange(r[0], r[1], r[2], r[3]);
  }

  private displayUrl(): string {
    const url = this.imageUri;
    if (url.length === 0) return url;
    return url.startsWith('/') ? ApiConfig.BASE_URL + url : url;
  }

  aboutToAppear(): void { this.notify(); }

  build() {
    Column() {
      // 非 bare 模式显示顶部栏
      if (!this.bare) {
        Row() {
          Text('✕').fontSize(24).fontColor('#FFFFFF').onClick(() => { this.onCancel(); })
          Blank()
          Text('拖角缩放 · 拖中心移动').fontSize(13).fontColor('#FFFFFF80')
          Blank()
          Text('确定').fontSize(16).fontColor('#4CAF50')
            .onClick(() => { const r = this.getCorrected(); this.onConfirm(r[0], r[1], r[2], r[3]); })
        }
        .width('100%').padding(16).backgroundColor('#000000')
      }

      Stack() {
        Image(this.displayUrl())
          .width('100%').height('100%').objectFit(ImageFit.Contain)
          .onComplete((e?: Object) => {
            if (e !== undefined) {
              const r = e as Record<string, number>;
              if (r['loadingStatus'] as number === 1 && r['width'] as number > 0) {
                this.imgW = r['width'] as number;
                this.imgH = r['height'] as number;
              }
            }
          })

        Column().width('100%').height(this.pxY()).backgroundColor('#00000099').position({ x: 0, y: 0 })
        Column().width('100%').height(700).backgroundColor('#00000099').position({ x: 0, y: this.pxY() + this.pxH() })
        Column().width(this.pxX()).height(this.pxH()).backgroundColor('#00000099').position({ x: 0, y: this.pxY() })
        Column().width(350).height(this.pxH()).backgroundColor('#00000099').position({ x: this.pxX() + this.pxW(), y: this.pxY() })

        Column().width(this.pxW()).height(this.pxH()).border({ width: 2, color: '#4CAF50' })
          .position({ x: this.pxX(), y: this.pxY() })

        Column().width(this.pxW()).height(this.pxH()).position({ x: this.pxX(), y: this.pxY() })
          .gesture(PanGesture({ fingers: 1, distance: 5 })
            .onActionStart(() => { this.startX = this.cropX; this.startY = this.cropY; })
            .onActionUpdate((e: GestureEvent) => {
              this.cropX = this.startX + e.offsetX / Math.max(1, this.cw);
              this.cropY = this.startY + e.offsetY / Math.max(1, this.ch);
              this.notify();
            }))

        Column()
          .width(HANDLE_SIZE).height(HANDLE_SIZE).borderRadius(HANDLE_SIZE / 2)
          .backgroundColor('#4CAF50').border({ width: 2, color: '#FFFFFF' })
          .position({ x: this.pxX() - HANDLE_SIZE / 2, y: this.pxY() - HANDLE_SIZE / 2 })
          .gesture(PanGesture({ fingers: 1, distance: 1 })
            .onActionStart(() => { this.rsX = this.cropX; this.rsY = this.cropY;
              this.rsW = this.cropW; this.rsH = this.cropH; })
            .onActionUpdate((e: GestureEvent) => {
              const dx = e.offsetX / Math.max(1, this.cw);
              const dy = e.offsetY / Math.max(1, this.ch);
              const min = MIN_SIZE / Math.max(1, this.cw);
              this.cropX = this.rsX + dx; this.cropY = this.rsY + dy;
              this.cropW = Math.max(min, this.rsW - dx); this.cropH = Math.max(min, this.rsH - dy);
              this.notify();
            }))
        Column()
          .width(HANDLE_SIZE).height(HANDLE_SIZE).borderRadius(HANDLE_SIZE / 2)
          .backgroundColor('#4CAF50').border({ width: 2, color: '#FFFFFF' })
          .position({ x: this.pxX() + this.pxW() - HANDLE_SIZE / 2, y: this.pxY() - HANDLE_SIZE / 2 })
          .gesture(PanGesture({ fingers: 1, distance: 1 })
            .onActionStart(() => { this.rsX = this.cropX; this.rsY = this.cropY;
              this.rsW = this.cropW; this.rsH = this.cropH; })
            .onActionUpdate((e: GestureEvent) => {
              const dx = e.offsetX / Math.max(1, this.cw);
              const dy = e.offsetY / Math.max(1, this.ch);
              const min = MIN_SIZE / Math.max(1, this.cw);
              this.cropY = this.rsY + dy;
              this.cropW = Math.max(min, this.rsW + dx); this.cropH = Math.max(min, this.rsH - dy);
              this.notify();
            }))
        Column()
          .width(HANDLE_SIZE).height(HANDLE_SIZE).borderRadius(HANDLE_SIZE / 2)
          .backgroundColor('#4CAF50').border({ width: 2, color: '#FFFFFF' })
          .position({ x: this.pxX() - HANDLE_SIZE / 2, y: this.pxY() + this.pxH() - HANDLE_SIZE / 2 })
          .gesture(PanGesture({ fingers: 1, distance: 1 })
            .onActionStart(() => { this.rsX = this.cropX; this.rsY = this.cropY;
              this.rsW = this.cropW; this.rsH = this.cropH; })
            .onActionUpdate((e: GestureEvent) => {
              const dx = e.offsetX / Math.max(1, this.cw);
              const dy = e.offsetY / Math.max(1, this.ch);
              const min = MIN_SIZE / Math.max(1, this.cw);
              this.cropX = this.rsX + dx;
              this.cropW = Math.max(min, this.rsW - dx); this.cropH = Math.max(min, this.rsH + dy);
              this.notify();
            }))
        Column()
          .width(HANDLE_SIZE).height(HANDLE_SIZE).borderRadius(HANDLE_SIZE / 2)
          .backgroundColor('#4CAF50').border({ width: 2, color: '#FFFFFF' })
          .position({ x: this.pxX() + this.pxW() - HANDLE_SIZE / 2, y: this.pxY() + this.pxH() - HANDLE_SIZE / 2 })
          .gesture(PanGesture({ fingers: 1, distance: 1 })
            .onActionStart(() => { this.rsX = this.cropX; this.rsY = this.cropY;
              this.rsW = this.cropW; this.rsH = this.cropH; })
            .onActionUpdate((e: GestureEvent) => {
              const dx = e.offsetX / Math.max(1, this.cw);
              const dy = e.offsetY / Math.max(1, this.ch);
              const min = MIN_SIZE / Math.max(1, this.cw);
              this.cropW = Math.max(min, this.rsW + dx); this.cropH = Math.max(min, this.rsH + dy);
              this.notify();
            }))
      }
      .width('100%')
      .layoutWeight(this.bare ? 1 : 1)
      .backgroundColor('#000000')
      .onAreaChange((_old: Area, newArea: Area) => {
        this.cw = newArea.width as number;
        this.ch = newArea.height as number;
      })

      // 非 bare 模式显示底部栏
      if (!this.bare) {
        Row({ space: 12 }) {
          Button('取消').fontSize(15).fontColor('#FFFFFF').backgroundColor('#666666')
            .borderRadius(12).layoutWeight(1)
            .onClick(() => { this.onCancel(); })
          Button('确认裁剪').fontSize(15).fontColor('#FFFFFF').backgroundColor('#4CAF50')
            .borderRadius(12).layoutWeight(1)
            .onClick(() => { const r = this.getCorrected(); this.onConfirm(r[0], r[1], r[2], r[3]); })
        }
        .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 24 }).backgroundColor('#000000')
      }
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }

}
