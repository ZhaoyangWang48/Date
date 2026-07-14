import { DriftOceanCanvas } from '../components/DriftOceanCanvas';
import { MoodOption, MoodTypes } from '../constants/MoodTypes';
import { DriftBottle, ResonanceLeaf, ResonanceMoodOption, ResonanceMoodTypes } from '../models/DriftBottle';
import { DriftBottleViewModel } from '../viewmodels/DriftBottleViewModel';

@Entry
@Component
struct DriftBottlePage {
  @State activeTab: number = 0;
  @State content: string = '';
  @State mood: string = 'calm';
  @State current: DriftBottle | undefined = undefined;
  @State bottles: DriftBottle[] = [];
  @State resonances: ResonanceLeaf[] = [];
  @State pickupCount: number = 0;
  @State selectedResonance: string = 'moved';
  @State resonanceSent: boolean = false;
  @State message: string = '';
  @State loading: boolean = false;
  @State loadingData: boolean = false;
  private readonly viewModel: DriftBottleViewModel = new DriftBottleViewModel();

  aboutToAppear(): void {
    this.load();
  }

  private async load(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.loadingData) return;
    this.loadingData = true;
    try {
      this.bottles = await this.viewModel.listMyBottles(context);
      this.resonances = await this.viewModel.listMyResonances(context);
      this.pickupCount = await this.viewModel.getTodayPickupCount(context);
    } catch (_) {
      this.message = '暂时无法读取漂流瓶，请稍后重试';
    } finally {
      this.loadingData = false;
    }
  }

  private switchTab(index: number): void {
    this.activeTab = index;
    this.message = '';
  }

  private async throwBottle(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.loading) return;
    if (this.content.trim().length === 0) {
      this.message = '请先写下想交给远方的话';
      return;
    }
    if (this.remainingThrows() <= 0) {
      this.message = '今天已经投出 3 个漂流瓶了';
      return;
    }
    this.loading = true;
    this.message = '';
    try {
      const result = await this.viewModel.throwBottle(context, 0, this.content, this.mood);
      this.message = result.message;
      if (result.success) {
        this.content = '';
        await this.load();
      }
    } finally {
      this.loading = false;
    }
  }

  private async pickup(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.loading) return;
    if (this.pickupCount >= 3) {
      this.message = '今天已经捞取 3 次了，明天再来看看吧';
      return;
    }
    this.loading = true;
    this.message = '';
    try {
      const result = await this.viewModel.pickupBottle(context);
      this.message = result.message;
      if (result.success && result.data !== undefined) {
        this.current = result.data;
        this.pickupCount += 1;
        this.selectedResonance = 'moved';
        this.resonanceSent = false;
      }
    } finally {
      this.loading = false;
    }
  }

  private async resonate(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined || this.current === undefined || this.loading || this.resonanceSent) return;
    this.loading = true;
    this.message = '';
    try {
      const result = await this.viewModel.sendResonance(context, this.current.id, this.selectedResonance);
      this.message = result.message;
      if (result.success) this.resonanceSent = true;
    } finally {
      this.loading = false;
    }
  }
  build() {
    Stack() {
      DriftOceanCanvas()
      Scroll() {
        Column({ space: 18 }) {
          this.pageHeader()
          this.tabBar()
          if (this.activeTab === 0) {
            this.throwContent()
          } else if (this.activeTab === 1) {
            this.pickupContent()
          } else {
            this.mineContent()
          }
          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(13)
              .lineHeight(20)
              .fontColor('#235E54')
              .width('100%')
              .padding({ left: 14, right: 14, top: 11, bottom: 11 })
              .borderRadius(14)
              .backgroundColor('#E9F3F0')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .constraintSize({ minHeight: '100%' })
        .padding({ left: 20, right: 20, top: 28, bottom: 36 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  private pageHeader(): void {
    Column({ space: 8 }) {
      Row({ space: 6 }) {
        Text('‹')
          .fontSize(34)
          .fontColor('#DCEDEA')
          .width(28)
          .onClick(() => { this.getUIContext().getRouter().back(); })
        Text('漂流瓶')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
      }
      .width('100%')
      Text('匿名地把一句话交给海，也接住远方的故事。')
        .fontSize(14)
        .lineHeight(22)
        .fontColor('#C4D9DD')
        .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private tabBar(): void {
    Row({ space: 6 }) {
      ForEach(['扔出', '捞起', '我的共鸣'], (label: string, index: number) => {
        Text(label)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(14)
          .fontWeight(this.activeTab === index ? FontWeight.Medium : FontWeight.Regular)
          .fontColor(this.activeTab === index ? '#245F55' : '#C8DCE0')
          .padding({ top: 10, bottom: 10 })
          .borderRadius(13)
          .backgroundColor(this.activeTab === index ? '#F1F7F5' : '#21495A')
          .onClick(() => { this.switchTab(index); })
      })
    }
    .width('100%')
    .padding(4)
    .borderRadius(17)
    .backgroundColor('#173E50')
  }
  @Builder
  private throwContent(): void {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 3 }) {
          Text('写给远方')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#193530')
          Text('瓶子会在海上停留三天')
            .fontSize(12)
            .fontColor('#71827F')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`今日剩余 ${this.remainingThrows()}/3`)
          .fontSize(12)
          .fontColor('#247A63')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor('#E4F2ED')
      }
      .width('100%')

      TextArea({ placeholder: '写下一段想交给远方的话…', text: this.content })
        .height(136)
        .padding(14)
        .fontColor('#1C302D')
        .backgroundColor('#F2F5F4')
        .border({ width: 1, color: '#D4E0DD' })
        .borderRadius(16)
        .onChange((value: string) => { this.content = value; })

      Text('此刻的心情')
        .fontSize(13)
        .fontColor('#667B77')
        .width('100%')
      Row({ space: 6 }) {
        ForEach(MoodTypes.OPTIONS, (option: MoodOption) => {
          Text(option.label)
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .fontSize(12)
            .fontColor(this.mood === option.key ? '#FFFFFF' : '#247A63')
            .padding({ top: 9, bottom: 9 })
            .borderRadius(14)
            .backgroundColor(this.mood === option.key ? '#247A63' : '#E4F2ED')
            .onClick(() => { this.mood = option.key; })
        }, (option: MoodOption) => option.key)
      }
      .width('100%')
      Button(this.loading ? '投入中…' : '投入大海')
        .width('100%')
        .height(48)
        .enabled(!this.loading && this.remainingThrows() > 0)
        .fontColor('#FFFFFF')
        .backgroundColor('#247A63')
        .borderRadius(15)
        .onClick(() => { this.throwBottle(); })
    }
    .width('100%')
    .padding(18)
    .borderRadius(22)
    .backgroundColor('#F8FBFA')
    .border({ width: 1, color: '#D8E5E2' })
  }
  @Builder
  private pickupContent(): void {
    Column({ space: 16 }) {
      Row() {
        Column({ space: 3 }) {
          Text(this.current === undefined ? '海面上的故事' : '来自远方的漂流瓶')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor('#193530')
          Text('每一次捞取都保持匿名')
            .fontSize(12)
            .fontColor('#71827F')
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Text(`${this.pickupCount}/3 次`)
          .fontSize(12)
          .fontColor('#247A63')
          .padding({ left: 10, right: 10, top: 6, bottom: 6 })
          .borderRadius(12)
          .backgroundColor('#E4F2ED')
      }
      .width('100%')

      if (this.current === undefined) {
        Column({ space: 8 }) {
          Text('≈')
            .fontSize(34)
            .fontColor('#4E8F82')
          Text('海面上漂着未知的故事')
            .fontSize(16)
            .fontColor('#365B54')
          Text('轻轻捞起一个，也许会遇见一句刚好需要的话。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor('#71827F')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ top: 20, bottom: 20, left: 16, right: 16 })
        .borderRadius(17)
        .backgroundColor('#EDF5F2')

        Button(this.loading ? '寻找中…' : '捞一个看看')
          .width('100%')
          .height(48)
          .enabled(!this.loading && this.pickupCount < 3)
          .fontColor('#FFFFFF')
          .backgroundColor('#247A63')
          .borderRadius(15)
          .onClick(() => { this.pickup(); })
      } else {
        Text(this.current!.content)
          .fontSize(17)
          .lineHeight(28)
          .fontColor('#203E38')
          .width('100%')
          .padding(18)
          .borderRadius(17)
          .backgroundColor('#EDF5F2')
        Text('送一片共鸣叶')
          .fontSize(13)
          .fontColor('#667B77')
          .width('100%')

        Row({ space: 6 }) {
          ForEach(ResonanceMoodTypes.OPTIONS, (item: ResonanceMoodOption) => {
            Text(item.label)
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .fontSize(12)
              .fontColor(this.selectedResonance === item.key ? '#FFFFFF' : '#247A63')
              .padding({ top: 8, bottom: 8 })
              .borderRadius(14)
              .backgroundColor(this.selectedResonance === item.key ? '#247A63' : '#E4F2ED')
              .onClick(() => {
                if (!this.resonanceSent) this.selectedResonance = item.key;
              })
          }, (item: ResonanceMoodOption) => item.key)
        }
        .width('100%')

        Button(this.resonanceSent ? '共鸣已送出' : this.loading ? '送出中…' : '送出共鸣')
          .width('100%')
          .height(46)
          .enabled(!this.loading && !this.resonanceSent)
          .fontColor('#FFFFFF')
          .backgroundColor(this.resonanceSent ? '#7CA597' : '#247A63')
          .borderRadius(15)
          .onClick(() => { this.resonate(); })
        if (this.pickupCount < 3) {
          Button('再捞一个')
            .width('100%')
            .height(44)
            .enabled(!this.loading)
            .fontColor('#247A63')
            .backgroundColor('#E4F2ED')
            .borderRadius(14)
            .onClick(() => { this.pickup(); })
        }
      }
    }
    .width('100%')
    .padding(18)
    .borderRadius(22)
    .backgroundColor('#F8FBFA')
    .border({ width: 1, color: '#D8E5E2' })
  }
  @Builder
  private mineContent(): void {
    Column({ space: 14 }) {
      Row() {
        Text('我扔出的瓶子')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#193530')
        Blank()
        Text(`${this.bottles.length} 个`)
          .fontSize(12)
          .fontColor('#71827F')
      }
      .width('100%')

      if (this.loadingData && this.bottles.length === 0) {
        Text('正在寻找你的漂流瓶…')
          .fontSize(14)
          .fontColor('#71827F')
          .width('100%')
          .padding(16)
      } else if (this.bottles.length === 0) {
        Text('还没有瓶子，写一句话让它漂向远方。')
          .fontSize(14)
          .lineHeight(21)
          .fontColor('#71827F')
          .width('100%')
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#EDF5F2')
      } else {
        ForEach(this.bottles, (item: DriftBottle) => {
          Column({ space: 7 }) {
            Text(item.content)
              .fontSize(15)
              .lineHeight(22)
              .fontColor('#203E38')
              .width('100%')
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Row() {
              Text(item.isExpired() ? '已沉入海底' : `${item.remainingDays()} 天后沉入海底`)
                .fontSize(12)
                .fontColor('#71827F')
              Blank()
              Text(`${item.resonanceCount} 片共鸣叶`)
                .fontSize(12)
                .fontColor('#247A63')
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(16)
          .backgroundColor('#EDF5F2')
        }, (item: DriftBottle) => item.id.toString())
      }

      Row() {
        Text('收到的共鸣')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor('#193530')
        Blank()
        Text(`${this.resonances.length} 片`)
          .fontSize(12)
          .fontColor('#71827F')
      }
      .width('100%')
      .margin({ top: 8 })

      if (!this.loadingData && this.resonances.length === 0) {
        Text('暂时还没有收到共鸣，瓶子仍在远方漂流。')
          .fontSize(14)
          .lineHeight(21)
          .fontColor('#71827F')
          .width('100%')
          .padding(16)
          .borderRadius(15)
          .backgroundColor('#EDF5F2')
      } else {
        ForEach(this.resonances, (item: ResonanceLeaf) => {
          Row({ space: 11 }) {
            Text(ResonanceMoodTypes.getOption(item.mood).icon)
              .fontSize(20)
              .fontColor(ResonanceMoodTypes.getOption(item.mood).color)
            Column({ space: 3 }) {
              Text(ResonanceMoodTypes.getOption(item.mood).label)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor('#203E38')
              Text(item.bottleContentSnippet)
                .fontSize(12)
                .fontColor('#71827F')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
          }
          .width('100%')
          .padding(13)
          .borderRadius(15)
          .backgroundColor('#EDF5F2')
        }, (item: ResonanceLeaf) => item.id.toString())
      }
    }
    .width('100%')
    .padding(18)
    .borderRadius(22)
    .backgroundColor('#F8FBFA')
    .border({ width: 1, color: '#D8E5E2' })
  }

  private remainingThrows(): number {
    const todayCount = this.bottles.filter((bottle: DriftBottle) => this.isToday(bottle.throwTime)).length;
    return Math.max(0, 3 - todayCount);
  }

  private isToday(value: string): boolean {
    const date = new Date(value);
    const now = new Date();
    return date.getFullYear() === now.getFullYear() && date.getMonth() === now.getMonth() &&
      date.getDate() === now.getDate();
  }
}
