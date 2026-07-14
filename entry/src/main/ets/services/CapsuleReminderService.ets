import { common, Context } from '@kit.AbilityKit';
import { notificationManager } from '@kit.NotificationKit';
import { TimeCapsule } from '../models/TimeCapsule';
import { TimeCapsuleRepository } from '../repositories/TimeCapsuleRepository';

/**
 * 仅在应用前台运行时检查胶囊到期状态，并发布顶部系统通知。
 * 应用进入后台后停止计时；重新回到前台时，不补发后台期间错过的提醒。
 */
export class CapsuleReminderService {
  private static readonly NOTIFICATION_ID: number = 720001;
  private static readonly repository: TimeCapsuleRepository = new TimeCapsuleRepository();
  private static capsules: TimeCapsule[] = [];
  private static notifiedIds: number[] = [];
  private static countdownTimer: number = -1;
  private static foregroundStartedAt: number = 0;
  private static sessionId: number = 0;
  private static context: Context | undefined = undefined;

  static start(context: Context): void {
    if (CapsuleReminderService.countdownTimer >= 0) return;
    CapsuleReminderService.context = context;
    CapsuleReminderService.capsules = [];
    CapsuleReminderService.notifiedIds = [];
    CapsuleReminderService.foregroundStartedAt = Date.now();
    CapsuleReminderService.sessionId += 1;
    const currentSession = CapsuleReminderService.sessionId;
    console.info(`[CapsuleReminder] started at ${CapsuleReminderService.foregroundStartedAt}`);

    CapsuleReminderService.countdownTimer = setInterval(() => {
      CapsuleReminderService.checkReadyCapsules();
    }, 1000);
    CapsuleReminderService.loadCapsules(context, currentSession);
  }

  static stop(): void {
    if (CapsuleReminderService.countdownTimer >= 0) {
      clearInterval(CapsuleReminderService.countdownTimer);
    }
    CapsuleReminderService.countdownTimer = -1;
    CapsuleReminderService.foregroundStartedAt = 0;
    CapsuleReminderService.sessionId += 1;
    CapsuleReminderService.context = undefined;
    CapsuleReminderService.capsules = [];
    CapsuleReminderService.notifiedIds = [];
  }

  static synchronize(capsules: TimeCapsule[]): void {
    if (CapsuleReminderService.countdownTimer < 0) return;
    CapsuleReminderService.capsules = capsules;
    CapsuleReminderService.requestPermissionIfNeeded(capsules);
  }

  private static async loadCapsules(context: Context, sessionId: number): Promise<void> {
    const result = await CapsuleReminderService.repository.list(context);
    console.info(`[CapsuleReminder] loaded code=${result.code} count=${result.data?.length ?? 0}`);
    if (sessionId !== CapsuleReminderService.sessionId || CapsuleReminderService.countdownTimer < 0) return;
    if (result.code === 200 && result.data !== undefined) {
      CapsuleReminderService.capsules = result.data;
      CapsuleReminderService.requestPermissionIfNeeded(result.data);
    }
  }

  private static checkReadyCapsules(): void {
    const now = Date.now();
    const ready: TimeCapsule[] = CapsuleReminderService.capsules.filter((capsule: TimeCapsule) => {
      if (capsule.isOpened || CapsuleReminderService.notifiedIds.indexOf(capsule.id) >= 0) return false;
      const wasPendingWhenForegrounded = capsule.remainingMilliseconds(CapsuleReminderService.foregroundStartedAt) > 0;
      return wasPendingWhenForegrounded && capsule.isReady(now);
    });
    if (ready.length === 0) return;
    console.info(`[CapsuleReminder] ready count=${ready.length} now=${now}`);

    ready.forEach((capsule: TimeCapsule) => {
      CapsuleReminderService.notifiedIds.push(capsule.id);
    });
    CapsuleReminderService.publishReady(ready);
  }

  private static requestPermissionIfNeeded(capsules: TimeCapsule[]): void {
    const hasPendingCapsule = capsules.some((capsule: TimeCapsule) => !capsule.isOpened && !capsule.isReady());
    if (!hasPendingCapsule || CapsuleReminderService.context === undefined) return;
    CapsuleReminderService.ensureNotificationEnabled(CapsuleReminderService.context);
  }

  private static async ensureNotificationEnabled(context: Context): Promise<void> {
    try {
      const enabled = await notificationManager.isNotificationEnabled();
      console.info(`[CapsuleReminder] notification enabled=${enabled}`);
      if (!enabled) {
        await notificationManager.requestEnableNotification(context as common.UIAbilityContext);
      }
    } catch (error) {
      console.error(`[CapsuleReminder] notification permission failed: ${JSON.stringify(error)}`);
    }
  }

  private static async publishReady(ready: TimeCapsule[]): Promise<void> {
    try {
      await notificationManager.publish({
        id: CapsuleReminderService.NOTIFICATION_ID,
        notificationSlotType: notificationManager.SlotType.SERVICE_INFORMATION,
        isAlertOnce: false,
        content: {
          notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
          normal: {
            title: '植忆 · 时光胶囊',
            text: ready.length === 1 ? '你的时光胶囊已经到期，可以开启了' : `有 ${ready.length} 枚时光胶囊已经到期`
          }
        }
      });
      console.info(`[CapsuleReminder] published count=${ready.length}`);
    } catch (error) {
      console.error(`[CapsuleReminder] notification failed: ${JSON.stringify(error)}`);
    }
  }
}
