import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppRoutes } from '../constants/AppRoutes';
import { TokenStorage } from '../services/TokenStorage';
import { ServerEndpointStorage } from '../services/ServerEndpointStorage';

const DOMAIN = 0x0000;
const TAG = 'ZhiyiEntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (error) {
      hilog.error(DOMAIN, TAG, 'Failed to set color mode. Cause: %{public}s', JSON.stringify(error));
    }
    hilog.info(DOMAIN, TAG, 'Application created');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Application destroyed');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    ServerEndpointStorage.load(this.context).then(() => TokenStorage.hasToken(this.context)).then((hasToken: boolean) => {
      this.loadPage(windowStage, hasToken ? AppRoutes.HOME : AppRoutes.LOGIN);
    }).catch((error: Error) => {
      hilog.error(DOMAIN, TAG, 'Failed to read token. Cause: %{public}s', JSON.stringify(error));
      this.loadPage(windowStage, AppRoutes.LOGIN);
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Window stage destroyed');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Application foregrounded');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Application backgrounded');
  }

  private loadPage(windowStage: window.WindowStage, route: string): void {
    windowStage.loadContent(route, (error) => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load page. Cause: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Initial page loaded');
    });
  }
}
