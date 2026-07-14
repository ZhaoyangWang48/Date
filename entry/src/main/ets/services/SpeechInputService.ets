import { abilityAccessCtrl, Context, Permissions } from '@kit.AbilityKit';
import { speechRecognizer } from '@kit.CoreSpeechKit';
import { SpeechInputStatus, SpeechInputUpdate } from '../models/SpeechInputState';

export type SpeechInputListener = (update: SpeechInputUpdate) => void;

interface RecognizerOption {
  enablePartialResult: boolean;
}

/**
 * Core Speech Kit 实时语音输入。recognitionMode=0 由识别引擎直接采集麦克风，
 * 无需应用额外维护 AudioCapturer 和 writeAudio 的分片时序。
 */
export class SpeechInputService {
  private static engine: speechRecognizer.SpeechRecognitionEngine | undefined = undefined;
  private static listener: SpeechInputListener | undefined = undefined;
  private static status: SpeechInputStatus = SpeechInputStatus.IDLE;
  private static sessionId: string = '';
  private static finalText: string = '';
  private static partialText: string = '';
  private static sessionSequence: number = 0;
  private static timeoutId: number = 0;

  static async start(context: Context, listener: SpeechInputListener): Promise<boolean> {
    if (SpeechInputService.status === SpeechInputStatus.STARTING ||
      SpeechInputService.status === SpeechInputStatus.LISTENING ||
      SpeechInputService.status === SpeechInputStatus.PROCESSING) return false;

    SpeechInputService.cancel();
    SpeechInputService.listener = listener;
    SpeechInputService.finalText = '';
    SpeechInputService.partialText = '';
    const sessionId = `zhiyi-asr-${Date.now()}-${++SpeechInputService.sessionSequence}`;
    SpeechInputService.sessionId = sessionId;
    SpeechInputService.notify(SpeechInputStatus.STARTING, '', '正在连接语音识别…');

    try {
      const permission: Permissions = 'ohos.permission.MICROPHONE';
      const permissionResult = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, [permission]);
      if (permissionResult.authResults.length === 0 || permissionResult.authResults[0] !== 0) {
        SpeechInputService.fail(sessionId, '未获得麦克风权限，请授权后重试');
        return false;
      }

      const engine = await SpeechInputService.createEngine();
      if (SpeechInputService.sessionId !== sessionId) {
        engine.shutdown();
        return false;
      }
      SpeechInputService.engine = engine;
      SpeechInputService.bindListener(engine);

      const recognizerOption: RecognizerOption = { enablePartialResult: true };
      const extraParams: Record<string, Object> = {
        'recognitionMode': 0,
        'vadBegin': 10000,
        'vadEnd': 1500,
        'maxAudioDuration': 60000,
        'recognizerOption': recognizerOption
      };
      engine.startListening({
        sessionId: sessionId,
        audioInfo: { audioType: 'pcm', sampleRate: 16000, soundChannel: 1, sampleBit: 16 },
        extraParams: extraParams
      });
      SpeechInputService.notify(SpeechInputStatus.LISTENING, '', '正在听…再次点击即可停止');
      SpeechInputService.timeoutId = setTimeout(() => { SpeechInputService.stop(); }, 60000);
      return true;
    } catch (error) {
      SpeechInputService.fail(sessionId, SpeechInputService.friendlyError(error));
      return false;
    }
  }

  static stop(): void {
    if (SpeechInputService.status !== SpeechInputStatus.LISTENING &&
      SpeechInputService.status !== SpeechInputStatus.STARTING) return;
    SpeechInputService.clearTimeout();
    SpeechInputService.notify(SpeechInputStatus.PROCESSING,
      SpeechInputService.displayText(), '正在整理识别结果…');
    try {
      SpeechInputService.engine?.finish(SpeechInputService.sessionId);
    } catch (error) {
      SpeechInputService.fail(SpeechInputService.sessionId, SpeechInputService.friendlyError(error));
    }
  }

  static cancel(): void {
    SpeechInputService.clearTimeout();
    const activeSession = SpeechInputService.sessionId;
    const activeListener = SpeechInputService.listener;
    try {
      if (activeSession.length > 0) SpeechInputService.engine?.cancel(activeSession);
    } catch (_) { }
    try { SpeechInputService.engine?.shutdown(); } catch (_) { }
    SpeechInputService.engine = undefined;
    SpeechInputService.listener = undefined;
    SpeechInputService.sessionId = '';
    SpeechInputService.finalText = '';
    SpeechInputService.partialText = '';
    SpeechInputService.status = SpeechInputStatus.IDLE;
    activeListener?.(new SpeechInputUpdate(SpeechInputStatus.IDLE, '', ''));
  }

  private static async createEngine(): Promise<speechRecognizer.SpeechRecognitionEngine> {
    const modes: number[] = [0, 1];
    let lastError: Object | undefined = undefined;
    for (let i = 0; i < modes.length; i++) {
      try {
        const extraParams: Record<string, Object> = { 'locate': 'CN', 'recognizerMode': 'short' };
        return await speechRecognizer.createEngine({ language: 'zh-CN', online: modes[i], extraParams: extraParams });
      } catch (error) {
        lastError = error;
      }
    }
    throw new Error(lastError === undefined ? '系统语音识别服务不可用' : SpeechInputService.errorDetail(lastError));
  }

  private static bindListener(engine: speechRecognizer.SpeechRecognitionEngine): void {
    engine.setListener({
      onStart: (sessionId: string, _eventMessage: string): void => {
        if (!SpeechInputService.isCurrent(sessionId)) return;
        SpeechInputService.notify(SpeechInputStatus.LISTENING,
          SpeechInputService.displayText(), '正在听…再次点击即可停止');
      },
      onEvent: (sessionId: string, eventCode: number, _eventMessage: string): void => {
        if (!SpeechInputService.isCurrent(sessionId)) return;
        if (eventCode === 3 && SpeechInputService.status === SpeechInputStatus.LISTENING) {
          SpeechInputService.notify(SpeechInputStatus.PROCESSING,
            SpeechInputService.displayText(), '正在整理识别结果…');
        }
      },
      onResult: (sessionId: string, result: speechRecognizer.SpeechRecognitionResult): void => {
        if (!SpeechInputService.isCurrent(sessionId)) return;
        SpeechInputService.acceptResult(result);
      },
      onComplete: (sessionId: string, _eventMessage: string): void => {
        if (!SpeechInputService.isCurrent(sessionId)) return;
        SpeechInputService.complete(sessionId);
      },
      onError: (sessionId: string, errorCode: number, errorMessage: string): void => {
        if (!SpeechInputService.isCurrent(sessionId)) return;
        SpeechInputService.fail(sessionId, `语音识别失败（${errorCode}）：${errorMessage}`);
      }
    });
  }

  private static acceptResult(result: speechRecognizer.SpeechRecognitionResult): void {
    const text = result.result.trim();
    if (result.isFinal) {
      if (text.length > 0) {
        if (SpeechInputService.finalText.length === 0 || text.startsWith(SpeechInputService.finalText)) {
          SpeechInputService.finalText = text;
        } else if (!SpeechInputService.finalText.endsWith(text)) {
          SpeechInputService.finalText += text;
        }
      }
      SpeechInputService.partialText = '';
    } else {
      SpeechInputService.partialText = text;
    }
    SpeechInputService.notify(SpeechInputService.status, SpeechInputService.displayText(),
      SpeechInputService.status === SpeechInputStatus.PROCESSING ? '正在整理识别结果…' : '正在听…再次点击即可停止');
  }

  private static complete(sessionId: string): void {
    SpeechInputService.clearTimeout();
    const text = SpeechInputService.displayText().trim();
    if (text.length === 0) {
      SpeechInputService.fail(sessionId, '没有听清内容，请靠近麦克风后重试');
      return;
    }
    const activeListener = SpeechInputService.listener;
    try { SpeechInputService.engine?.shutdown(); } catch (_) { }
    SpeechInputService.engine = undefined;
    SpeechInputService.listener = undefined;
    SpeechInputService.sessionId = '';
    SpeechInputService.finalText = '';
    SpeechInputService.partialText = '';
    SpeechInputService.status = SpeechInputStatus.COMPLETED;
    activeListener?.(new SpeechInputUpdate(SpeechInputStatus.COMPLETED, text, '语音文字已追加'));
  }

  private static fail(sessionId: string, message: string): void {
    if (SpeechInputService.sessionId.length > 0 && sessionId !== SpeechInputService.sessionId) return;
    SpeechInputService.clearTimeout();
    const activeListener = SpeechInputService.listener;
    try { SpeechInputService.engine?.shutdown(); } catch (_) { }
    SpeechInputService.engine = undefined;
    SpeechInputService.listener = undefined;
    SpeechInputService.sessionId = '';
    SpeechInputService.finalText = '';
    SpeechInputService.partialText = '';
    SpeechInputService.status = SpeechInputStatus.ERROR;
    activeListener?.(new SpeechInputUpdate(SpeechInputStatus.ERROR, '', message));
  }

  private static notify(status: SpeechInputStatus, text: string, message: string): void {
    SpeechInputService.status = status;
    SpeechInputService.listener?.(new SpeechInputUpdate(status, text, message));
  }

  private static displayText(): string {
    if (SpeechInputService.partialText.length === 0) return SpeechInputService.finalText;
    if (SpeechInputService.finalText.length === 0 || SpeechInputService.partialText.startsWith(SpeechInputService.finalText)) return SpeechInputService.partialText;
    return SpeechInputService.finalText + SpeechInputService.partialText;
  }

  private static isCurrent(sessionId: string): boolean {
    return sessionId.length > 0 && sessionId === SpeechInputService.sessionId;
  }

  private static clearTimeout(): void {
    if (SpeechInputService.timeoutId > 0) clearTimeout(SpeechInputService.timeoutId);
    SpeechInputService.timeoutId = 0;
  }

  private static friendlyError(error: Object): string {
    const detail = SpeechInputService.errorDetail(error);
    if (detail.includes('1002200006')) return '语音识别正在忙，请稍后重试';
    if (detail.includes('permission') || detail.includes('201')) return '麦克风权限不可用，请在系统设置中允许后重试';
    return `语音输入暂不可用：${detail}`;
  }

  private static errorDetail(error: Object): string {
    try {
      const value = JSON.stringify(error);
      return value.length > 0 && value !== '{}' ? value : '系统语音服务不可用';
    } catch (_) { return '系统语音服务不可用'; }
  }
}
