import { CapsuleBloomCanvas } from '../components/CapsuleBloomCanvas';
import { TimeCapsule } from '../models/TimeCapsule';
import { CapsuleTtsService } from '../services/CapsuleTtsService';
import { TimeCapsuleViewModel } from '../viewmodels/TimeCapsuleViewModel';

@Entry
@Component
struct CapsuleOpenPage {
  @State capsule: TimeCapsule | undefined = undefined;
  @State message: string = '正在唤醒这段记忆…';
  @State opened: boolean = false;
  private readonly viewModel: TimeCapsuleViewModel = new TimeCapsuleViewModel();

  aboutToAppear(): void { this.loadAndOpen(); }
  aboutToDisappear(): void { CapsuleTtsService.stop(); }
  private async loadAndOpen(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as Record<string, number>;
    const id = params['capsuleId']; const context = this.getUIContext().getHostContext();
    if (typeof id !== 'number' || context === undefined) { this.message = '胶囊暂时找不到了'; return; }
    const current = await this.viewModel.get(context, id); if (current === undefined) { this.message = '胶囊暂时找不到了'; return; }
    if (!current.isOpened) {
      const result = await this.viewModel.open(context, id); if (!result.success || result.capsule === undefined) { this.message = result.message; return; }
      this.capsule = result.capsule;
    } else this.capsule = current;
    this.opened = true; this.message = '来自过去的你';
  }
  private speak(): void { if (this.capsule !== undefined && this.capsule.isOpened) CapsuleTtsService.speak(this.capsule.content); }
  build() {
    Column({ space: 18 }) {
      Row() { Text('‹').fontSize(34).fontColor($r('app.color.primary')).onClick(() => { this.getUIContext().getRouter().back(); }); Blank(); Text('开启胶囊').fontSize(20).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')); Blank(); Text(' ').width(28); }.width('100%')
      CapsuleBloomCanvas({ mood: this.capsule?.mood ?? 'calm', onComplete: () => { if (this.opened) this.speak(); } })
      Text(this.message).fontSize(15).fontColor($r('app.color.text_secondary')).width('100%').textAlign(TextAlign.Center)
      if (this.capsule !== undefined && this.capsule.isOpened) {
        Text(this.capsule.content).fontSize(19).lineHeight(30).fontColor($r('app.color.text_primary')).width('100%').padding(20).borderRadius(20).backgroundColor($r('app.color.surface'))
        Button('朗读这封信').width('100%').height(46).fontColor($r('app.color.on_primary')).backgroundColor($r('app.color.primary')).borderRadius(14).onClick(() => { this.speak(); })
      }
    }.width('100%').height('100%').padding({ left: 24, right: 24, top: 28, bottom: 28 }).backgroundColor($r('app.color.app_background'))
  }
}
