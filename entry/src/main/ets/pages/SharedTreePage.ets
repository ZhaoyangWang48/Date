import { MemoryCard } from '../components/MemoryCard';
import { AppRoutes } from '../constants/AppRoutes';
import { MoodSelector } from '../components/MoodSelector';
import { StatePanel } from '../components/StatePanel';
import { Memory } from '../models/Memory';
import { TreeHole } from '../models/TreeHole';
import { TreeMember } from '../models/TreeMember';
import { ImagePickerService } from '../services/ImagePickerService';
import { TokenStorage } from '../services/TokenStorage';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { TreeHoleViewModel } from '../viewmodels/TreeHoleViewModel';
import { AgentViewModel } from '../viewmodels/AgentViewModel';
import { AgentChatResponse, AgentSourceCitation } from '../models/AgentChat';

interface ChatMessage {
  role: string;
  content: string;
  sources?: AgentSourceCitation[];
}

@Entry
@Component
struct SharedTreePage {
  @State trees: TreeHole[] = [];
  @State members: TreeMember[] = [];
  @State memories: Memory[] = [];
  @State selectedId: number = 0;
  @State selectedName: string = '';
  @State selectedCode: string = '';
  @State nickname: string = '记忆守护者';
  @State createName: string = '';
  @State joinCode: string = '';
  @State setupMode: number = 0;
  @State content: string = '';
  @State mood: string = 'calm';
  @State imageUri: string = '';
  @State message: string = '';
  @State loading: boolean = false;
  @State publishing: boolean = false;
  @State errorMessage: string = '';
  @State currentUserId: number = 0;
  @State showChat: boolean = false;
  @State chatQuestion: string = '';
  @State chatMessages: ChatMessage[] = [];
  @State chatLoading: boolean = false;
  @State expandedSourceIndex: number = -1;
  private readonly treeVm: TreeHoleViewModel = new TreeHoleViewModel();
  private readonly memoryVm: MemoryViewModel = new MemoryViewModel();
  private readonly picker: ImagePickerService = new ImagePickerService();
  private readonly agentVm: AgentViewModel = new AgentViewModel();

  aboutToAppear(): void {
    this.initialize();
  }

  private async initialize(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.nickname = await TokenStorage.getNickname(context);
      this.currentUserId = await TokenStorage.getUserId(context);
      this.trees = await this.treeVm.listMine(context);
    } catch (error) {
      this.errorMessage = '树洞数据加载失败，请稍后重试';
    }
    this.loading = false;
  }

  private async open(tree: TreeHole): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.selectedId = tree.id;
      this.selectedName = tree.name;
      this.selectedCode = tree.inviteCode;
      this.members = await this.treeVm.members(context, tree.id);
      this.memories = await this.memoryVm.listTreeHoleMemories(context, tree.id);
      this.message = '';
    } catch (error) {
      this.errorMessage = '树洞详情加载失败，请稍后重试';
    }
    this.loading = false;
  }

  private async create(): Promise<void> {
    this.message = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const tree = await this.treeVm.create(context, this.createName);
      if (tree === undefined) {
        this.message = '请填写树洞名称';
        return;
      }
      this.trees = await this.treeVm.listMine(context);
      this.createName = '';
      await this.open(tree);
    } catch (error) {
      this.message = '创建树洞失败，请稍后重试';
    }
  }

  private async join(): Promise<void> {
    this.message = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const tree = await this.treeVm.join(context, this.joinCode);
      if (tree === undefined) {
        this.message = '邀请码无效，可使用演示邀请码 REMOVED_SECRET';
        return;
      }
      this.trees = await this.treeVm.listMine(context);
      this.joinCode = '';
      await this.open(tree);
    } catch (error) {
      this.message = '加入树洞失败，请稍后重试';
    }
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
    this.publishing = true;
    this.message = '';
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const result = await this.memoryVm.createMemory(context, this.content, this.imageUri, this.mood,
        this.selectedId);
      this.message = result.message;
      if (result.success) {
        this.content = '';
        this.imageUri = '';
        this.memories = await this.memoryVm.listTreeHoleMemories(context, this.selectedId);
      }
    } catch (error) {
      this.message = '发布共享记忆失败，请稍后重试';
    }
    this.publishing = false;
  }

  private async deleteMemory(memoryId: number): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const result = await this.memoryVm.deleteMemory(context, memoryId);
      this.message = result.message;
      if (result.success) this.memories = await this.memoryVm.listTreeHoleMemories(context, this.selectedId);
    } catch (error) {
      this.message = '删除共享记忆失败，请稍后重试';
    }
  }

  private openCommonDay(): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.COMMON_DAY });
    } catch (_error) {
      this.message = '共同一天暂时无法打开';
    }
  }

  private async sendQuestion(): Promise<void> {
    if (this.chatQuestion.trim().length === 0 || this.chatLoading) return;
    const question = this.chatQuestion.trim();
    this.chatQuestion = '';
    this.chatMessages = this.chatMessages.concat([{ role: 'user', content: question }]);
    this.chatLoading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      const resp = await this.agentVm.chat(context, this.selectedId, question);
      if (resp === undefined) {
        this.chatMessages = this.chatMessages.concat([{ role: 'agent', content: 'Rememberer 暂时无法回应，请稍后重试' }]);
      } else {
        this.chatMessages = this.chatMessages.concat([{ role: 'agent', content: resp.answer, sources: resp.sources }]);
      }
    } catch (_error) {
      this.chatMessages = this.chatMessages.concat([{ role: 'agent', content: '网络请求失败，请检查连接后重试' }]);
    }
    this.chatLoading = false;
  }

  build() {
    Stack() {
      Scroll() {
        Column({ space: 0 }) {
        if (this.selectedId === 0) {
          Text('树洞')
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text('我的树洞')
            .fontSize(13)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 6, bottom: 16 })
            .width('100%')
          Row({ space: 8 }) {
            Button('新建')
              .layoutWeight(1).fontSize(14)
              .fontColor(this.setupMode === 0 ? $r('app.color.on_primary') : $r('app.color.primary'))
              .backgroundColor(this.setupMode === 0 ? $r('app.color.primary') : $r('app.color.primary_soft'))
              .borderRadius(12).onClick(() => { this.setupMode = 0; })
            Button('加入')
              .layoutWeight(1).fontSize(14)
              .fontColor(this.setupMode === 1 ? $r('app.color.on_primary') : $r('app.color.primary'))
              .backgroundColor(this.setupMode === 1 ? $r('app.color.primary') : $r('app.color.primary_soft'))
              .borderRadius(12).onClick(() => { this.setupMode = 1; })
          }
          .width('100%').margin({ bottom: 10 })
          if (this.setupMode === 0) {
            TextInput({ placeholder: '树洞名称', text: this.createName })
              .height(50).padding({ left: 14, right: 14 }).backgroundColor($r('app.color.surface')).borderRadius(14)
              .border({ width: 1, color: $r('app.color.outline') }).onChange((value: string) => { this.createName = value; })
            Button('创建').width('100%').height(48).margin({ top: 10 }).fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary')).borderRadius(14).onClick(() => { this.create(); })
          } else {
            TextInput({ placeholder: '邀请码', text: this.joinCode })
              .height(50).padding({ left: 14, right: 14 }).backgroundColor($r('app.color.surface')).borderRadius(14)
              .border({ width: 1, color: $r('app.color.outline') }).onChange((value: string) => { this.joinCode = value; })
            Button('加入树洞').width('100%').height(48).margin({ top: 10 }).fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary')).borderRadius(14).onClick(() => { this.join(); })
          }
          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(14)
              .fontColor($r('app.color.error'))
              .margin({ top: 12 })
              .width('100%')
          }

          if (this.loading) {
            StatePanel({ title: '正在加载树洞', description: '演示树洞马上出现。', stateIcon: '⏳' })
          } else if (this.errorMessage.length > 0) {
            StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
          } else if (this.trees.length === 0) {
            StatePanel({ title: '尚未加入树洞', description: '创建一个树洞，或输入演示邀请码 REMOVED_SECRET。', stateIcon: '🌿' })
          } else {
            ForEach(this.trees, (tree: TreeHole) => {
              Row() {
                Column({ space: 4 }) {
                  Text(tree.name)
                    .fontSize(17)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.text_primary'))
                  Text(`邀请码：${tree.inviteCode}`)
                    .fontSize(13)
                    .fontColor($r('app.color.text_secondary'))
                }
                .alignItems(HorizontalAlign.Start)
                Blank()
                Text('›')
                  .fontSize(28)
                  .fontColor($r('app.color.primary'))
              }
              .width('100%')
              .padding(16)
              .margin({ top: 10 })
              .borderRadius(14)
              .backgroundColor($r('app.color.surface'))
              .border({ width: 1, color: $r('app.color.outline') })
              .onClick(() => {
                this.open(tree);
              })
            }, (tree: TreeHole) => tree.id.toString())
          }
        } else {
          Text('‹')
            .fontSize(34)
            .fontWeight(FontWeight.Lighter)
            .fontColor($r('app.color.primary'))
            .onClick(() => {
              this.selectedId = 0;
            })
          Text(this.selectedName)
            .fontSize(25)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .width('100%')
          Text(`邀请码：${this.selectedCode}`)
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 5 })
            .width('100%')

          Row({ space: 8 }) {
            Button('共同一天')
              .fontSize(14)
              .fontColor($r('app.color.primary'))
              .backgroundColor($r('app.color.primary_soft'))
              .borderRadius(16)
              .onClick(() => { this.openCommonDay(); })
            Button('💬 记忆守护者')
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor($r('app.color.primary'))
              .borderRadius(16)
              .onClick(() => { this.showChat = true; })
          }
          .margin({ top: 14 })

          if (this.loading) {
            StatePanel({ title: '正在打开树洞', description: '成员和共享记忆正在加载。', stateIcon: '⏳' })
          } else if (this.errorMessage.length > 0) {
            StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
          } else {
            Text(`成员 ${this.members.length} 人`)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 22, bottom: 8 })
              .width('100%')
            Row({ space: 8 }) {
              ForEach(this.members, (member: TreeMember) => {
                Text(`${member.nickname} · ${member.role === 'OWNER' ? '创建者' : '成员'}`)
                  .fontSize(13)
                  .fontColor($r('app.color.primary'))
                  .padding({ left: 9, right: 9, top: 6, bottom: 6 })
                  .borderRadius(14)
                  .backgroundColor($r('app.color.primary_soft'))
              }, (member: TreeMember) => member.id.toString())
            }
            .width('100%')

            Text('发布共享记忆')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 22, bottom: 8 })
              .width('100%')
            TextArea({ placeholder: '写下想和大家分享的时刻…', text: this.content })
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
            Button(this.publishing ? '发布中…' : '发布共享记忆')
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

            Text('树洞记忆')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 26, bottom: 10 })
              .width('100%')
            if (this.memories.length === 0) {
              StatePanel({ title: '还没有共享记忆', description: '写下第一条树洞记忆，让这棵树开始发芽。', stateIcon: '🍃' })
            } else {
              ForEach(this.memories, (memory: Memory) => {
                Column({ space: 6 }) {
                  MemoryCard({ memory: memory })
                  if (memory.authorId === this.currentUserId) {
                    Button('删除我的记忆')
                      .fontSize(13)
                      .fontColor($r('app.color.error'))
                      .backgroundColor($r('app.color.primary_soft'))
                      .borderRadius(12)
                      .onClick(() => { this.deleteMemory(memory.id); })
                  }
                }
                .width('100%')
              }, (memory: Memory) => memory.id.toString())
            }
          }
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

      if (this.showChat) {
        Column() {
          Row() {
            Text('记忆守护者 Rememberer').fontSize(17).fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text('✕').fontSize(22).fontColor($r('app.color.text_secondary'))
              .onClick(() => { this.showChat = false; this.chatMessages = []; this.expandedSourceIndex = -1; })
          }
          .width('100%').padding(16)

          Scroll() {
            Column({ space: 12 }) {
              ForEach(this.chatMessages, (msg: ChatMessage, index: number) => {
                Column() {
                  if (msg.role === 'agent') {
                    Row() {
                      Text('💬').fontSize(14)
                      Text('Rememberer').fontSize(12).fontColor($r('app.color.text_secondary'))
                    }.margin({ bottom: 4 })
                  }
                  Text(msg.content).fontSize(14)
                    .fontColor(msg.role === 'agent' ? $r('app.color.text_primary') : '#FFFFFF')
                    .padding(12).borderRadius(14)
                    .backgroundColor(msg.role === 'agent' ? '#F5F5F5' : $r('app.color.primary'))
                    .constraintSize({ maxWidth: '85%' })
                    .textAlign(msg.role === 'agent' ? TextAlign.Start : TextAlign.End)
                  if (msg.role === 'agent' && msg.sources !== undefined && msg.sources.length > 0) {
                    Column() {
                      if (this.expandedSourceIndex === index) {
                        Row() {
                          Text('📎').fontSize(11)
                          Text(`引用 ${msg.sources!.length} 条记忆 ▲`).fontSize(11)
                            .fontColor($r('app.color.primary'))
                        }
                        .padding({ top: 4, bottom: 4, left: 8, right: 8 })
                        .borderRadius(8).backgroundColor('#E8F5E9')
                        .onClick(() => { this.expandedSourceIndex = -1; })
                        Column({ space: 4 }) {
                          ForEach(msg.sources!, (src: AgentSourceCitation) => {
                            Column() {
                              Text(`${src.authorName} · ${src.date}`)
                                .fontSize(10).fontColor($r('app.color.primary'))
                              Text(src.contentSnippet)
                                .fontSize(12).fontColor($r('app.color.text_primary'))
                            }
                            .padding(8).borderRadius(6)
                            .backgroundColor('#00000006').width('100%')
                            .alignItems(HorizontalAlign.Start)
                          })
                        }
                        .margin({ top: 4 })
                      } else {
                        Row() {
                          Text('📎').fontSize(11)
                          Text(`引用 ${msg.sources!.length} 条记忆 ▼`).fontSize(11)
                            .fontColor($r('app.color.primary'))
                        }
                        .padding({ top: 4, bottom: 4, left: 8, right: 8 })
                        .borderRadius(8).backgroundColor('#E8F5E9')
                        .onClick(() => { this.expandedSourceIndex = index; })
                      }
                    }
                    .margin({ top: 6 })
                    .alignItems(HorizontalAlign.Start)
                  }
                }
                .width('100%')
                .alignItems(msg.role === 'agent' ? HorizontalAlign.Start : HorizontalAlign.End)
              }, (_msg: ChatMessage, index: number) => index.toString())

              if (this.chatLoading) {
                Row() {
                  Text('⏳ 思考中...').fontSize(13).fontColor($r('app.color.text_secondary'))
                }.margin({ left: 16 })
              }
            }
            .width('100%').padding({ left: 16, right: 16 })
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1).scrollBar(BarState.Off)

          Row({ space: 8 }) {
            TextArea({ placeholder: '向记忆守护者提问...', text: this.chatQuestion })
              .layoutWeight(1).height(44).padding(10)
              .backgroundColor($r('app.color.surface'))
              .borderRadius(22).border({ width: 1, color: $r('app.color.outline') })
              .onChange((value: string) => { this.chatQuestion = value; })
            Button('发送').fontSize(13).fontColor($r('app.color.on_primary'))
              .backgroundColor($r('app.color.primary'))
              .borderRadius(22).height(44).padding({ left: 16, right: 16 })
              .enabled(!this.chatLoading)
              .onClick(() => { this.sendQuestion(); })
          }
          .width('100%').padding(12)
        }
        .width('100%').height('100%')
        .backgroundColor($r('app.color.app_background'))
        .zIndex(200)
      }
    }
    .width('100%')
    .height('100%')
  }
}
