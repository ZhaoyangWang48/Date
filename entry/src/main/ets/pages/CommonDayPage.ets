import { HourTimeline } from '../components/HourTimeline';
import { MemoryCard } from '../components/MemoryCard';
import { MoodSelector } from '../components/MoodSelector';
import { StatePanel } from '../components/StatePanel';
import { Memory } from '../models/Memory';
import { ImagePickerService } from '../services/ImagePickerService';
import { TokenStorage } from '../services/TokenStorage';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { TreeHole } from '../models/TreeHole';
import { TreeMember } from '../models/TreeMember';
import { TreeHoleViewModel } from '../viewmodels/TreeHoleViewModel';
import { CollageExportResult, CommonDayCollageService } from '../services/CommonDayCollageService';

@Entry
@Component
struct CommonDayPage {
  @State selectedDate: Date = new Date();
  @State dateText: string = '';
  @State selectedHour: number = new Date().getHours();
  @State memories: Memory[] = [];
  @State content: string = '';
  @State mood: string = 'calm';
  @State imageUri: string = '';
  @State nickname: string = '记忆守护者';
  @State message: string = '';
  @State loading: boolean = false;
  @State publishing: boolean = false;
  @State errorMessage: string = '';
  @State trees: TreeHole[] = [];
  @State members: TreeMember[] = [];
  @State selectedTreeId: number = 0;
  @State exporting: boolean = false;
  @State exportMessage: string = '';
  private readonly vm: MemoryViewModel = new MemoryViewModel();
  private readonly picker: ImagePickerService = new ImagePickerService();
  private readonly treeVm: TreeHoleViewModel = new TreeHoleViewModel();
  private readonly collageService: CommonDayCollageService = new CommonDayCollageService();

  aboutToAppear(): void {
    this.dateText = this.format(this.selectedDate);
    this.initialize();
  }

  private async initialize(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.nickname = await TokenStorage.getNickname(context);
      this.trees = await this.treeVm.listMine(context);
      if (this.trees.length > 0) {
        const params = this.getUIContext().getRouter().getParams() as Record<string, number>;
        const requestedTreeId: number = params === undefined ? 0 : params['treeId'];
        const requestedTree: TreeHole | undefined =
          this.trees.find((tree: TreeHole) => tree.id === requestedTreeId);
        this.selectedTreeId = requestedTree === undefined ? this.trees[0].id : requestedTree.id;
        await this.load();
      } else {
        this.errorMessage = '请先创建或加入一个树洞';
      }
    } catch (error) {
      this.errorMessage = '共同日数据加载失败，请稍后重试';
    }
  }

  private async load(): Promise<void> {
    if (this.selectedTreeId === 0) { this.memories = []; this.members = []; return; }
    this.loading = true;
    this.errorMessage = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.members = await this.treeVm.members(context, this.selectedTreeId);
      this.memories = await this.vm.listDateMemories(context, this.selectedTreeId, this.dateText);
    } catch (error) {
      this.errorMessage = '共同日数据加载失败，请稍后重试';
    }
    this.loading = false;
  }

  private async changeDate(value: Date): Promise<void> {
    this.selectedDate = value;
    this.dateText = this.format(this.selectedDate);
    this.exportMessage = '';
    await this.load();
  }

  private async exportSelectedHour(): Promise<void> {
    if (this.exporting) return;
    this.exportMessage = '';
    if (this.members.length < 2 || this.members.length > 4) {
      this.exportMessage = `当前树洞有 ${this.members.length} 人，仅支持 2–4 人导出`;
      return;
    }

    const selectedPhotos: Memory[] = [];
    const missingMembers: string[] = [];
    for (let i: number = 0; i < this.members.length; i++) {
      const member: TreeMember = this.members[i];
      const candidates: Memory[] = this.memories
        .filter((memory: Memory) => memory.hour === this.selectedHour &&
          memory.authorId === member.userId && memory.imageUrl.length > 0)
        .sort((a: Memory, b: Memory) => b.createdAt.localeCompare(a.createdAt));
      if (candidates.length === 0) {
        missingMembers.push(member.nickname);
      } else {
        selectedPhotos.push(candidates[0]);
      }
    }

    if (missingMembers.length > 0) {
      this.exportMessage = `无法导出：${missingMembers.join('、')} 尚未上传 ${this.selectedHour}:00 的图片`;
      return;
    }

    this.exporting = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const result: CollageExportResult = await this.collageService.export(
        context, selectedPhotos, this.dateText, this.selectedHour);
      this.exportMessage = result.message;
    } catch (_error) {
      this.exportMessage = '导出失败，请稍后重试';
    }
    this.exporting = false;
  }

  private async chooseImage(): Promise<void> {
    try {
      const uri = await this.picker.pickOneImage();
      if (uri.length > 0) {
        this.imageUri = uri;
      }
    } catch (error) {
      this.message = '图片选择失败，请重新选择';
    }
  }

  private async publish(): Promise<void> {
    if (this.selectedTreeId === 0) { this.message = '请先选择树洞'; return; }
    this.publishing = true;
    this.message = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const result = await this.vm.createMemoryAt(context, this.content, this.imageUri, this.mood,
        this.dateText, this.selectedHour, this.selectedTreeId);
      this.message = result.message;
      if (result.success) {
        this.content = '';
        this.imageUri = '';
        await this.load();
      }
    } catch (error) {
      this.message = '发布失败，请稍后重试';
    }
    this.publishing = false;
  }

  private format(date: Date): string {
    return `${date.getFullYear()}-${this.pad(date.getMonth() + 1)}-${this.pad(date.getDate())}`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Text('共同一天')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
        Text('把同一天不同小时的生活连成时间轴。')
          .fontSize(15)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10, bottom: 16 })
          .width('100%')
        Text('选择树洞')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .margin({ bottom: 10 })
        if (this.trees.length === 0) {
          Text('尚未加入树洞，请先创建或通过邀请码加入。')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: 14 })
        } else {
          Row({ space: 8 }) {
            ForEach(this.trees, (tree: TreeHole) => {
              Button(tree.name)
                .fontSize(14)
                .fontColor(this.selectedTreeId === tree.id ? $r('app.color.on_primary') : $r('app.color.primary'))
                .backgroundColor(this.selectedTreeId === tree.id ? $r('app.color.primary') : $r('app.color.primary_soft'))
                .borderRadius(14)
                .onClick(() => {
                  this.selectedTreeId = tree.id;
                  this.exportMessage = '';
                  this.load();
                })
            }, (tree: TreeHole) => tree.id.toString())
          }
          .width('100%')
          .margin({ bottom: 14 })
        }
        DatePicker({ selected: this.selectedDate })
          .lunar(false)
          .onDateChange((value: Date) => {
            this.changeDate(value);
          })
          .width('100%')
          .height(120)
          .backgroundColor($r('app.color.surface'))
          .borderRadius(18)

        Text(`${this.dateText} · 选择小时`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 22, bottom: 10 })
          .width('100%')
        HourTimeline({
          selectedHour: this.selectedHour,
          onChanged: (hour: number) => {
            this.selectedHour = hour;
            this.exportMessage = '';
          }
        })

        Column({ space: 8 }) {
          Text(`导出 ${this.dateText} ${this.selectedHour}:00 的共同图片`)
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text(this.members.length === 4 ?
            '四人按左上、左下、右上、右下排列' : '两人或三人横向并排排列')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
          Button(this.exporting ? '正在合成…' : '一键导出共同图片')
            .width('100%')
            .height(46)
            .enabled(!this.exporting)
            .fontColor($r('app.color.on_primary'))
            .backgroundColor($r('app.color.primary'))
            .borderRadius(14)
            .onClick(() => { this.exportSelectedHour(); })
          if (this.exportMessage.length > 0) {
            Text(this.exportMessage)
              .fontSize(13)
              .fontColor(this.exportMessage === '拼图已保存到相册' ?
                $r('app.color.primary') : $r('app.color.error'))
              .width('100%')
          }
        }
        .width('100%')
        .padding(16)
        .margin({ top: 16 })
        .backgroundColor($r('app.color.surface'))
        .borderRadius(16)
        .border({ width: 1, color: $r('app.color.outline') })

        Text(`发布 ${this.selectedHour}:00 的记录`)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 22, bottom: 8 })
          .width('100%')
        TextArea({ placeholder: '写下这个小时的生活片段…', text: this.content })
          .height(100)
          .padding(14)
          .backgroundColor($r('app.color.surface'))
          .borderRadius(14)
          .border({ width: 1, color: $r('app.color.outline') })
          .onChange((value: string) => {
            this.content = value;
          })
        MoodSelector({
          selectedMood: this.mood,
          onMoodChanged: (mood: string) => {
            this.mood = mood;
          }
        })
          .margin({ top: 12 })
        if (this.imageUri.length > 0) {
          Image(this.imageUri)
            .width('100%')
            .height(120)
            .objectFit(ImageFit.Cover)
            .borderRadius(14)
            .margin({ top: 12 })
        } else {
          Button('选择图片')
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.primary_soft'))
            .borderRadius(14)
            .margin({ top: 12 })
            .onClick(() => {
              this.chooseImage();
            })
        }
        Button(this.publishing ? '发布中…' : '发布这个小时的记录')
          .width('100%')
          .height(50)
          .enabled(!this.publishing)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .borderRadius(14)
          .margin({ top: 12 })
          .onClick(() => {
            this.publish();
          })
        if (this.message.length > 0) {
          Text(this.message)
            .fontSize(14)
            .fontColor(this.message === '记忆已种下' ? $r('app.color.primary') : $r('app.color.error'))
            .margin({ top: 10 })
            .width('100%')
        }

        Text(`${this.selectedHour}:00 的记忆`)
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ top: 26, bottom: 10 })
          .width('100%')
        if (this.loading) {
          StatePanel({ title: '正在整理这一天', description: '时间轴马上展开。', stateIcon: '⏳' })
        } else if (this.errorMessage.length > 0) {
          StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
        } else if (this.memories.filter((memory: Memory) => memory.hour === this.selectedHour).length === 0) {
          StatePanel({ title: '这个小时还没有记录', description: '换个小时看看，或者把此刻写进共同日。', stateIcon: '🍃' })
        } else {
          ForEach(this.memories.filter((memory: Memory) => memory.hour === this.selectedHour), (memory: Memory) => {
            MemoryCard({ memory: memory })
          }, (memory: Memory) => memory.id.toString())
        }
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 20, right: 20, top: 38, bottom: 28 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
