import { MoodTypes } from '../constants/MoodTypes';
import { MemoryTrack, RadioChannel, RadioChannels, RadioTheme } from '../models/RadioChannel';
import { RadioViewModel } from '../viewmodels/RadioViewModel';
import { TtsPlaybackState } from '../services/CapsuleTtsService';

@Entry
@Component
struct MemoryRadioPage {
  @State channelId: string = 'timeline';
  @State tracks: MemoryTrack[] = [];
  @State currentIndex: number = 0;
  @State ttsState: TtsPlaybackState = TtsPlaybackState.IDLE;
  @State message: string = '';
  private readonly viewModel: RadioViewModel = new RadioViewModel();

  aboutToAppear(): void { this.load(); }
  aboutToDisappear(): void { this.viewModel.stop(); }

  private async load(): Promise<void> {
    this.viewModel.stop();
    this.ttsState = TtsPlaybackState.IDLE;
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.message = '无法读取应用上下文';
      return;
    }
    this.tracks = await this.viewModel.load(context, RadioChannels.find(this.channelId));
    this.currentIndex = 0;
    this.message = this.tracks.length === 0 ? '这个频道暂时没有可朗读的记忆' : '';
  }

  private onTtsState(state: TtsPlaybackState, detail: string): void {
    this.ttsState = state;
    if (state === TtsPlaybackState.STARTING) this.message = '正在准备语音…';
    if (state === TtsPlaybackState.SPEAKING) this.message = '正在朗读这段记忆';
    if (state === TtsPlaybackState.COMPLETED) this.message = '朗读完成';
    if (state === TtsPlaybackState.STOPPED) this.message = '朗读已停止';
    if (state === TtsPlaybackState.ERROR) this.message = `朗读失败：${detail}`;
  }

  private async play(): Promise<void> {
    const track = this.currentTrack();
    if (track === undefined) {
      this.message = '这个频道还没有可朗读的记忆';
      return;
    }
    const accepted = await this.viewModel.play(track, (state: TtsPlaybackState, detail: string): void => {
      this.onTtsState(state, detail);
    });
    if (!accepted && this.ttsState !== TtsPlaybackState.ERROR) {
      this.ttsState = TtsPlaybackState.ERROR;
      this.message = '朗读服务暂不可用，请检查网络和系统语音服务';
    }
  }

  private stop(): void { this.viewModel.stop(); }

  private next(): void {
    if (this.tracks.length === 0) return;
    this.currentIndex = (this.currentIndex + 1) % this.tracks.length;
    this.play();
  }

  private async favorite(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.currentTrack() === undefined) return;
    this.tracks = await this.viewModel.toggleFavorite(context, this.tracks, this.currentIndex);
    this.message = this.currentTrack()!.isFavorited ? '已收藏这段记忆' : '已取消收藏';
  }

  private currentTrack(): MemoryTrack | undefined { return this.tracks[this.currentIndex]; }
  private currentTheme(): RadioTheme { return RadioChannels.find(this.channelId).theme; }
  private isSpeaking(): boolean { return this.ttsState === TtsPlaybackState.STARTING || this.ttsState === TtsPlaybackState.SPEAKING; }
  private currentText(): string {
    const track = this.currentTrack();
    if (track === undefined) return '这个频道暂时没有可播放的记忆。';
    return track.memory.content.length > 0 ? track.memory.content : '一张影像记忆，也值得被慢慢回看。';
  }

  build() {
    Stack() {
      Column().width('100%').height('100%').linearGradient({ direction: GradientDirection.Top,
        colors: [[this.currentTheme().backgroundStart, 0], [this.currentTheme().backgroundEnd, 1]] });
      Scroll() {
        Column({ space: 18 }) {
          Row() {
            Text('‹').fontSize(34).fontColor(this.currentTheme().accentColor).onClick(() => { this.viewModel.stop(); this.getUIContext().getRouter().back(); });
            Text('记忆电台').fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF');
          }.width('100%')

          Text('让过去的自己，慢慢说给现在的你听。').fontSize(14).fontColor(this.currentTheme().secondaryTextColor).width('100%')

          Scroll() {
            Row({ space: 8 }) {
              ForEach(RadioChannels.LIST, (channel: RadioChannel) => {
                Text(`${channel.icon} ${channel.name}`).fontSize(13)
                  .fontColor(this.channelId === channel.id ? this.currentTheme().accentTextColor : '#FFFFFF')
                  .padding({ left: 13, right: 13, top: 9, bottom: 9 }).borderRadius(15)
                  .backgroundColor(this.channelId === channel.id ? this.currentTheme().accentColor : '#1CFFFFFF')
                  .onClick(() => { this.channelId = channel.id; this.load(); });
              }, (channel: RadioChannel) => channel.id)
            }
          }.width('100%').scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off)

          Text(RadioChannels.find(this.channelId).description).fontSize(13).fontColor(this.currentTheme().secondaryTextColor).width('100%')

          Column({ space: 14 }) {
            Text(this.currentTrack() === undefined ? '等待一段记忆' : this.currentTrack()!.memory.date).fontSize(14).fontColor(this.currentTheme().secondaryTextColor)
            Text(this.currentText()).fontSize(21).lineHeight(32).fontColor('#FFFFFF').maxLines(5)
              .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
            if (this.currentTrack() !== undefined) {
              Text(MoodTypes.getOption(this.currentTrack()!.memory.mood).label).fontSize(13).fontColor(this.currentTheme().secondaryTextColor)
            }
            Row({ space: 16 }) {
              Button(this.isSpeaking() ? '重新朗读' : '开始朗读').layoutWeight(1).height(48).fontColor(this.currentTheme().accentTextColor)
                .backgroundColor(this.currentTheme().accentColor).borderRadius(16).onClick(() => { this.play(); })
              Button(this.currentTrack() !== undefined && this.currentTrack()!.isFavorited ? '已收藏' : '收藏').height(48)
                .fontColor('#FFFFFF').backgroundColor('#20FFFFFF').borderRadius(16).onClick(() => { this.favorite(); })
            }.width('100%')
            if (this.isSpeaking()) {
            Button('停止朗读').width('100%').height(42).fontColor(this.currentTheme().accentColor).backgroundColor('#10FFFFFF')
                .borderRadius(14).onClick(() => { this.stop(); })
            }
            Button('下一段').width('100%').height(42).fontColor(this.currentTheme().accentColor).backgroundColor('#10FFFFFF')
              .borderRadius(14).onClick(() => { this.next(); })
          }
          .width('100%').padding(22).margin({ top: 12 }).borderRadius(24).backgroundColor(this.currentTheme().cardColor).border({ width: 1, color: '#28FFFFFF' })

          if (this.message.length > 0) { Text(this.message).fontSize(13).fontColor(this.currentTheme().secondaryTextColor).width('100%') }
          Text(`频道内共有 ${this.tracks.length} 段记忆`).fontSize(14).fontColor(this.currentTheme().secondaryTextColor).width('100%')
        }
        .alignItems(HorizontalAlign.Start).width('100%').padding({ left: 20, right: 20, top: 30, bottom: 36 })
      }.width('100%').height('100%').scrollBar(BarState.Off)
    }.width('100%').height('100%')
  }
}
