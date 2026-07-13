import { BusinessError } from '@kit.BasicServicesKit';
import { AppRoutes } from '../constants/AppRoutes';
import { ApiConfig } from '../constants/ApiConfig';
import { AuthViewModel } from '../viewmodels/AuthViewModel';

@Entry
@Component
struct LoginPage {
  @State username: string = '';
  @State password: string = '';
  @State message: string = '';
  @State loading: boolean = false;
  @State serverUrl: string = ApiConfig.BASE_URL;
  private readonly viewModel: AuthViewModel = new AuthViewModel();

  aboutToAppear(): void {
    this.serverUrl = ApiConfig.BASE_URL;
  }

  private async submit(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) {
      this.message = '无法获取应用上下文，请重新打开页面';
      return;
    }

    if (this.username.trim().length === 0 || this.password.length === 0) {
      this.message = '请输入用户名和密码';
      return;
    }

    this.loading = true;
    this.message = '';
    try {
      const result = await this.viewModel.login(context, this.username, this.password);
      this.loading = false;
      if (!result.success) {
        this.message = result.message;
        return;
      }
      this.replacePage(AppRoutes.HOME);
    } catch (error) {
      this.loading = false;
      this.message = '登录请求异常，请重试';
    }
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

  private openRegister(): void {
    try {
      this.getUIContext().getRouter().pushUrl({ url: AppRoutes.REGISTER }, (error: BusinessError) => {
        if (error) {
          this.message = '无法打开注册页面';
        }
      });
    } catch (error) {
      this.message = '无法打开注册页面';
    }
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        Text('植忆')
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        Text('欢迎回来。')
          .fontSize(16)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10, bottom: 42 })
          .width('100%')

        Text('登录')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .width('100%')

        TextInput({ placeholder: '用户名', text: this.username })
          .width('100%')
          .height(54)
          .margin({ top: 24 })
          .padding({ left: 16, right: 16 })
          .fontSize(16)
          .backgroundColor($r('app.color.surface'))
          .border({ width: 1, color: $r('app.color.outline') })
          .borderRadius(16)
          .onChange((value: string) => {
            this.username = value;
          })

        TextInput({ placeholder: '密码', text: this.password })
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

        if (this.message.length > 0) {
          Row({ space: 8 }) {
            Text(this.message)
              .fontSize(14)
              .fontColor($r('app.color.error'))
              .layoutWeight(1)
          }
          .width('100%')
          .padding(14)
          .margin({ top: 12 })
          .borderRadius(10)
          .backgroundColor('#FFF0F0')
        }

        Button(this.loading ? '登录中…' : '登录')
          .enabled(!this.loading)
          .width('100%')
          .height(54)
          .margin({ top: 24 })
          .fontSize(17)
          .fontColor($r('app.color.on_primary'))
          .backgroundColor(this.loading ? $r('app.color.text_secondary') : $r('app.color.primary'))
          .borderRadius(18)
          .onClick(() => {
            this.submit();
          })

        Text('演示账号：zhiyi / REMOVED_SECRET')
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 18 })

        Row({ space: 6 }) {
          Text('还没有账号？')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
          Text('去注册')
            .fontSize(14)
            .fontColor($r('app.color.primary'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              this.openRegister();
            })
        }
        .margin({ top: 24 })

        Row({ space: 6 }) {
          Text('服务器')
            .fontSize(11)
            .fontColor($r('app.color.text_secondary'))
          Text(this.serverUrl)
            .fontSize(11)
            .fontColor($r('app.color.primary'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 36 })
      }
      .alignItems(HorizontalAlign.Start)
      .width('100%')
      .padding({ left: 24, right: 24, top: 88, bottom: 32 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }
}
