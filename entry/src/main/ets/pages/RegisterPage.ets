import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { AuthViewModel } from '../viewmodels/AuthViewModel';

@Entry
@Component
struct RegisterPage {
  @State username: string = '';
  @State nickname: string = '';
  @State password: string = '';
  @State confirmPassword: string = '';
  @State message: string = '';
  @State loading: boolean = false;
  private readonly viewModel: AuthViewModel = new AuthViewModel();

  private async submit(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.message = '无法获取应用上下文，请重新打开页面';
      return;
    }

    this.loading = true;
    this.message = '';
    const result = await this.viewModel.register(context, this.username, this.password, this.confirmPassword,
      this.nickname);
    this.loading = false;
    if (!result.success) {
      this.message = result.message;
      return;
    }
    this.replacePage(AppRoutes.HOME);
  }

  private replacePage(route: string): void {
    try {
      this.getUIContext().getRouter().replaceUrl({ url: route }, (error: BusinessError) => {
        if (error) {
          this.message = '页面跳转失败，请重试';
        }
      });
    } catch (error) {
      this.message = '页面跳转失败，请重试';
    }
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Row({ space: 10 }) {
          Text('‹')
            .fontSize(34)
            .fontWeight(FontWeight.Lighter)
            .fontColor($r('app.color.primary'))
            .onClick(() => {
              this.goBack();
            })
          Text('创建账号')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')

        Text('注册后即可开始保存属于你的记忆。')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 12, bottom: 30 })
          .width('100%')

        TextInput({ placeholder: '用户名（至少 3 个字符）', text: this.username })
          .width('100%')
          .height(54)
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(16)
          .onChange((value: string) => {
            this.username = value;
          })

        TextInput({ placeholder: '昵称', text: this.nickname })
          .width('100%')
          .height(54)
          .margin({ top: 14 })
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(16)
          .onChange((value: string) => {
            this.nickname = value;
          })

        TextInput({ placeholder: '密码（至少 6 个字符）', text: this.password })
          .type(InputType.Password)
          .width('100%')
          .height(54)
          .margin({ top: 14 })
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(16)
          .onChange((value: string) => {
            this.password = value;
          })

        TextInput({ placeholder: '确认密码', text: this.confirmPassword })
          .type(InputType.Password)
          .width('100%')
          .height(54)
          .margin({ top: 14 })
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(16)
          .onChange((value: string) => {
            this.confirmPassword = value;
          })

        if (this.message.length > 0) {
          Text(this.message)
            .fontSize(14)
            .fontColor($r('app.color.error'))
            .width('100%')
            .margin({ top: 12 })
        }

        Button(this.loading ? '注册中…' : '注册并进入植忆')
          .enabled(!this.loading)
          .width('100%')
          .height(54)
          .margin({ top: 24 })
          .fontSize(17)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .borderRadius(18)
          .onClick(() => {
            this.submit();
          })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 24, right: 24, top: 38, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
