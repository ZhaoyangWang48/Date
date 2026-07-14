import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppRoutes } from '../constants/AppRoutes';
import { TokenStorage } from '../services/TokenStorage';
import { ServerEndpointStorage } from '../services/ServerEndpointStorage';
import { SpeechInputService } from '../services/SpeechInputService';
import { CapsuleReminderService } from '../services/CapsuleReminderService';

const DOMAIN = 0x0000;
const TAG = 'ZhiyiEntryAbility';

export default class EntryAbility extends UIAbility {
  private contentLoaded: boolean = false;
  private windowStage: window.WindowStage | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to set color mode. Cause: %{public}s', JSON.stringify(error));
    }
    hilog.info(DOMAIN, TAG, 'Application created');
  }

  onDestroy(): void {
    SpeechInputService.cancel();
    CapsuleReminderService.stop();
    hilog.info(DOMAIN, TAG, 'Application destroyed');
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    const targetRoute = want.parameters?.['targetRoute'] as string;
    if (targetRoute && targetRoute.length > 0) {
      AppStorage.setOrCreate('notify_target_route', targetRoute);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.windowStage = windowStage;

    // 立即加载启动页，避免白屏
    windowStage.loadContent(AppRoutes.SPLASH, (error) => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load splash page. Cause: %{public}s', JSON.stringify(error));
      }
    });

    // 后台探测服务器
    const startMs: number = Date.now();
    ServerEndpointStorage.probeAndSelect(this.context).then((endpoint: string) => {
      if (endpoint.length === 0) {
        hilog.warn(DOMAIN, TAG, 'All server probes failed, using default');
      } else {
        hilog.info(DOMAIN, TAG, `Server selected: ${endpoint}`);
      }
      return TokenStorage.hasToken(this.context);
    }).then((hasToken: boolean) => {
      // 保证启动页至少显示 600ms
      const elapsed: number = Date.now() - startMs;
      const remaining: number = elapsed < 600 ? (600 - elapsed) : 0;
      setTimeout(() => {
        const target = hasToken ? AppRoutes.HOME : AppRoutes.LOGIN;
        this.replacePage(target);
      }, remaining);
    }).catch((error: Error) => {
      hilog.error(DOMAIN, TAG, 'Failed to read token. Cause: %{public}s', JSON.stringify(error));
      this.replacePage(AppRoutes.LOGIN);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Window stage destroyed');
    this.windowStage = null;
  }

  onForeground(): void {
    if (this.contentLoaded) this.startCapsuleReminders();
    hilog.info(DOMAIN, TAG, 'Application foregrounded');
  }

  onBackground(): void {
    SpeechInputService.cancel();
    CapsuleReminderService.stop();
    hilog.info(DOMAIN, TAG, 'Application backgrounded');
  }

  private replacePage(route: string): void {
    if (this.windowStage === null) {
      hilog.error(DOMAIN, TAG, 'windowStage is null, cannot navigate to %{public}s', route);
      return;
    }
    try {
      this.windowStage.loadContent(route, (error) => {
        if (error.code) {
          hilog.error(DOMAIN, TAG, 'Failed to navigate to %{public}s. Cause: %{public}s', route, JSON.stringify(error));
          return;
        }
        this.contentLoaded = true;
        this.startCapsuleReminders();
        hilog.info(DOMAIN, TAG, 'Page loaded: %{public}s', route);
      });
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to navigate. Cause: %{public}s', JSON.stringify(error));
    }
  }

  private async startCapsuleReminders(): Promise<void> {
    if (await TokenStorage.hasToken(this.context)) {
      CapsuleReminderService.start(this.context);
    }
  }
}
