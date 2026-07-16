import { AppRoutes } from '../constants/AppRoutes';
import { MoodSelector } from '../components/MoodSelector';
import { VoiceInputButton } from '../components/VoiceInputButton';
import { CapsuleTimeOption, CapsuleTimeOptions, TimeCapsule } from '../models/TimeCapsule';
import { SpeechInputStatus, SpeechInputUpdate } from '../models/SpeechInputState';
import { CapsuleReminderService } from '../services/CapsuleReminderService';
import { SpeechInputService } from '../services/SpeechInputService';
import { TimeCapsuleViewModel } from '../viewmodels/TimeCapsuleViewModel';

@Entry
@Component
struct TimeCapsuleGardenPage {
  @State capsules: TimeCapsule[] = [];
  @State content: string = '';
  @State mood: string = 'calm';
  @State selectedTimeKey: string = 'day-7';
  @State loading: boolean = false;
  @State message: string = '';
  @State now: number = Date.now();
  @State speechStatus: SpeechInputStatus = SpeechInputStatus.IDLE;
  @State speechText: string = '';
  @State speechMessage: string = '';
  private readonly viewModel: TimeCapsuleViewModel = new TimeCapsuleViewModel();
  private countdownTimer: number = 0;

  aboutToAppear(): void { this.startCountdown(); this.load(); }
  aboutToDisappear(): void {
    if (this.countdownTimer > 0) clearInterval(this.countdownTimer);
    this.countdownTimer = 0;
    SpeechInputService.cancel();
  }

  private startCountdown(): void {
    if (this.countdownTimer > 0) clearInterval(this.countdownTimer);
    this.now = Date.now();
    this.countdownTimer = setInterval(() => {
      this.now = Date.now();
    }, 1000);
  }

  private async load(): Promise<void> {
    const context = this.getUIContext().getHostContext(); if (context === undefined) return;
    this.loading = true; this.capsules = await this.viewModel.list(context); this.loading = false; this.now = Date.now();
    CapsuleReminderService.synchronize(this.capsules);
  }

  private async create(): Promise<void> {
    const context = this.getUIContext().getHostContext(); if (context === undefined || this.loading) return;
    this.loading = true; this.message = '';
    const result = await this.viewModel.create(context, this.content, this.mood,
      CapsuleTimeOptions.openAtFrom(CapsuleTimeOptions.find(this.selectedTimeKey)));
    this.loading = false; this.message = result.message;
    if (result.success) { this.content = ''; await this.load(); }
  }

  private open(capsule: TimeCapsule): void {
    if (!capsule.isReady(this.now) && !capsule.isOpened) { this.message = capsule.remainingText(this.now); return; }
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.CAPSULE_OPEN, params: { capsuleId: capsule.id } });
    } catch (_) {
      this.message = '暂时无法打开胶囊，请稍后重试';
    }
  }

  private async toggleSpeech(): Promise<void> {
    if (this.speechStatus === SpeechInputStatus.LISTENING) {
      SpeechInputService.stop();
      return;
    }
    if (this.speechStatus === SpeechInputStatus.STARTING || this.speechStatus === SpeechInputStatus.PROCESSING) return;
    const context = this.getUIContext().getHostContext();
    if (context === undefined) { this.speechMessage = '无法读取应用上下文'; return; }
    this.speechText = '';
    await SpeechInputService.start(context, (update: SpeechInputUpdate): void => { this.onSpeechUpdate(update); });
  }

  private onSpeechUpdate(update: SpeechInputUpdate): void {
    this.speechStatus = update.status;
    this.speechText = update.text;
    this.speechMessage = update.message;
    if (update.status === SpeechInputStatus.COMPLETED && update.text.trim().length > 0) {
      const recognized = update.text.trim();
      this.content = this.content.length > 0 ? `${this.content}\n${recognized}` : recognized;
      this.speechText = '';
      this.message = '语音文字已追加，可继续编辑后封存';
    }
  }

  private speechBusy(): boolean {
    return this.speechStatus === SpeechInputStatus.STARTING ||
      this.speechStatus === SpeechInputStatus.LISTENING ||
      this.speechStatus === SpeechInputStatus.PROCESSING;
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Row() { Text('‹').fontSize(34).fontColor($r('app.color.primary')).onClick(() => { this.getUIContext().getRouter().back(); }); Text('时光胶囊').fontSize(28).fontWeight(FontWeight.Bold).fontColor($r('app.color.text_primary')); }
          .width('100%')
        Text('把今天写给未来的自己。到期之前，它会在树下静静等待。').fontSize(14).fontColor($r('app.color.text_secondary')).lineHeight(22).width('100%')
        Column({ space: 12 }) {
          Text('封存一段记忆').fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%')
          TextArea({ placeholder: '写下想留给未来的文字…', text: this.content }).height(116).padding(14).backgroundColor($r('app.color.app_background')).border({ width: 1, color: $r('app.color.outline') }).borderRadius(16).onChange((value: string) => { this.content = value; })
          Row() {
            VoiceInputButton({ status: this.speechStatus, onToggle: () => { this.toggleSpeech(); } })
            Blank()
            Text('最长 60 秒').fontSize(12).fontColor($r('app.color.text_secondary'))
          }.width('100%')
          if (this.speechText.length > 0) {
            Text(`识别中：${this.speechText}`).fontSize(13).fontColor($r('app.color.primary')).width('100%').maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          if (this.speechMessage.length > 0 && this.speechStatus !== SpeechInputStatus.COMPLETED) {
            Text(this.speechMessage).fontSize(12).fontColor(this.speechStatus === SpeechInputStatus.ERROR ? '#A94D4D' : $r('app.color.text_secondary')).width('100%')
          }
          MoodSelector({ selectedMood: this.mood, onMoodChanged: (value: string) => { this.mood = value; } })
          Text('开启时间').fontSize(13).fontColor($r('app.color.text_secondary')).width('100%')
          Scroll() {
            Row({ space: 8 }) { ForEach(CapsuleTimeOptions.OPTIONS, (option: CapsuleTimeOption) => {
              Text(option.label).fontSize(12).fontColor(this.selectedTimeKey === option.key ? $r('app.color.on_primary') : $r('app.color.primary')).padding({ left: 11, right: 11, top: 8, bottom: 8 }).borderRadius(14).backgroundColor(this.selectedTimeKey === option.key ? $r('app.color.primary') : $r('app.color.primary_soft')).onClick(() => { this.selectedTimeKey = option.key; });
            }, (option: CapsuleTimeOption) => option.key) }
          }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)
          Button(this.loading ? '正在封存…' : '埋入时光').width('100%').height(46).enabled(!this.loading && !this.speechBusy()).fontColor($r('app.color.on_primary')).backgroundColor($r('app.color.primary')).borderRadius(14).onClick(() => { this.create(); })
        }.width('100%').padding(16).borderRadius(20).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
        if (this.message.length > 0) { Text(this.message).fontSize(13).fontColor($r('app.color.primary')).width('100%') }
        Text('胶囊花园').fontSize(20).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')).width('100%').margin({ top: 8 })
        if (!this.loading && this.capsules.length === 0) {
          Text('还没有胶囊。种下第一封写给未来的信吧。').fontSize(14).fontColor($r('app.color.text_secondary')).width('100%').padding(22).borderRadius(16).backgroundColor($r('app.color.surface'))
        } else {
          ForEach(this.capsules, (capsule: TimeCapsule) => {
            Row({ space: 14 }) {
              Text(capsule.isOpened ? '✦' : capsule.isReady(this.now) ? '◉' : '●').fontSize(25).fontColor(capsule.isOpened || capsule.isReady(this.now) ? '#C99B3F' : '#9B8354')
              Column({ space: 4 }) { Text(capsule.isOpened ? '已开启的胶囊' : capsule.isReady(this.now) ? '等待开启' : '埋在时光里的信').fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary')); Text(capsule.remainingText(this.now)).fontSize(13).fontColor($r('app.color.text_secondary')); Text(capsule.displayContent()).fontSize(13).fontColor($r('app.color.text_secondary')).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis }); }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              Text('›').fontSize(24).fontColor($r('app.color.primary'))
            }.width('100%').padding(16).borderRadius(18).backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') }).onClick(() => { this.open(capsule); })
          }, (capsule: TimeCapsule) => capsule.id.toString())
        }
      }.alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 28, bottom: 32 })
    }.width('100%').height('100%').scrollBar(BarState.Off).backgroundColor($r('app.color.app_background'))
  }
}
