import { SpeechInputStatus } from '../models/SpeechInputState';

@Component
export struct VoiceInputButton {
  @Prop status: SpeechInputStatus = SpeechInputStatus.IDLE;
  onToggle: () => void = () => {};

  private label(): string {
    if (this.status === SpeechInputStatus.STARTING) return '正在连接…';
    if (this.status === SpeechInputStatus.LISTENING) return '● 停止并转成文字';
    if (this.status === SpeechInputStatus.PROCESSING) return '正在识别…';
    return '麦克风  语音输入';
  }

  build() {
    Button(this.label())
      .height(40)
      .enabled(this.status !== SpeechInputStatus.STARTING && this.status !== SpeechInputStatus.PROCESSING)
      .fontSize(13)
      .fontColor(this.status === SpeechInputStatus.LISTENING ? '#FFFFFF' : $r('app.color.primary'))
      .backgroundColor(this.status === SpeechInputStatus.LISTENING ? '#A94D4D' : $r('app.color.primary_soft'))
      .borderRadius(14)
      .onClick(() => { this.onToggle(); })
  }
}
