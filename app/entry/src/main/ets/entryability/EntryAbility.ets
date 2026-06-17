import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { TokenUtil } from '../common/TokenUtil';
import GlobalContext from '../common/GlobalContext';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    GlobalContext.getInstance().setContext(this.context)
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.loadInitialPage(windowStage);
  }

  private async loadInitialPage(windowStage: window.WindowStage): Promise<void> {
    try {
      const hasToken: boolean = await TokenUtil.hasToken();
      const initialPage: string = hasToken ? 'pages/MainTab' : 'pages/Login';
      // 调试开关：设为 true 时强制进入 Profile
      const isDebuggingProfile: boolean = false;

      if (isDebuggingProfile) {
        windowStage.loadContent('pages/Login', (err) => {
          if (err.code) {
            hilog.error(DOMAIN, 'testTag', 'Failed to load Profile. Cause: %{public}s', JSON.stringify(err));
          }
        });
        return;
      }
      windowStage.loadContent(initialPage, (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
          return;
        }
        hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      });
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to check token. Cause: %{public}s', JSON.stringify(error));
      windowStage.loadContent('pages/Login', (err) => {
        if (err.code) {
          hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        }
      });
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
