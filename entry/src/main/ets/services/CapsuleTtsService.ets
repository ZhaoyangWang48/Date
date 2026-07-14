import { textToSpeech } from '@kit.CoreSpeechKit';

export enum TtsPlaybackState {
  IDLE = 'idle',
  STARTING = 'starting',
  SPEAKING = 'speaking',
  COMPLETED = 'completed',
  STOPPED = 'stopped',
  ERROR = 'error'
}

export type TtsStateListener = (state: TtsPlaybackState, message: string) => void;

/**
 * 统一的记忆朗读服务。先查询本机可用中文音色，避免固定 person 导致
 * 不同机型创建引擎失败；页面通过回调获得真实的开始、结束和错误状态。
 */
export class CapsuleTtsService {
  private static engine: textToSpeech.TextToSpeechEngine | undefined = undefined;
  private static activeRequestId: string = '';
  private static activeListener: TtsStateListener | undefined = undefined;
  private static requestSequence: number = 0;

  static async speak(content: string, listener?: TtsStateListener): Promise<boolean> {
    const text = content.trim();
    if (text.length === 0) {
      listener?.(TtsPlaybackState.ERROR, '没有可朗读的文字');
      return false;
    }

    const requestId = `zhiyi-${Date.now()}-${++CapsuleTtsService.requestSequence}`;
    try {
      const engine = await CapsuleTtsService.getEngine();
      // 允许用户切换到下一段时立即替换上一段朗读。
      try { engine.stop(); } catch (_) { }
      CapsuleTtsService.activeRequestId = requestId;
      CapsuleTtsService.activeListener = listener;
      CapsuleTtsService.notify(requestId, TtsPlaybackState.STARTING, '正在准备语音');
      // 控制单次文本长度，避免长篇记忆触发 SDK 的文本长度限制。
      engine.speak(text.substring(0, 4000), { requestId: requestId });
      return true;
    } catch (error) {
      const message = CapsuleTtsService.errorMessage(error);
      listener?.(TtsPlaybackState.ERROR, message);
      console.error(`[CapsuleTts] create or speak failed: ${message}`);
      return false;
    }
  }

  static stop(): void {
    try {
      CapsuleTtsService.engine?.stop();
    } catch (error) {
      console.error(`[CapsuleTts] stop failed: ${CapsuleTtsService.errorMessage(error)}`);
    }
  }

  private static async getEngine(): Promise<textToSpeech.TextToSpeechEngine> {
    if (CapsuleTtsService.engine !== undefined) return CapsuleTtsService.engine;

    // 不调用 listVoices：部分模拟器会拒绝该预查询（401），但仍可直接创建中文引擎。
    // 按官方 API 的语言、音色和在线模式逐一回退，真实机和模拟器都能得到明确结果。
    const candidates: textToSpeech.CreateEngineParams[] = [
      { language: 'zh-CN', person: 0, online: 0 },
      { language: 'zh-CN', person: 0, online: 1 }
    ];
    let lastError = '';
    for (let i = 0; i < candidates.length; i++) {
      try {
        const engine = await textToSpeech.createEngine(candidates[i]);
        engine.setListener({
          onStart: (requestId: string, _response: textToSpeech.StartResponse): void => {
            CapsuleTtsService.notify(requestId, TtsPlaybackState.SPEAKING, '正在朗读');
          },
          onComplete: (requestId: string, _response: textToSpeech.CompleteResponse): void => {
            CapsuleTtsService.notify(requestId, TtsPlaybackState.COMPLETED, '朗读完成');
            CapsuleTtsService.clearActive(requestId);
          },
          onStop: (requestId: string, _response: textToSpeech.StopResponse): void => {
            CapsuleTtsService.notify(requestId, TtsPlaybackState.STOPPED, '朗读已停止');
            CapsuleTtsService.clearActive(requestId);
          },
          onError: (requestId: string, code: number, message: string): void => {
            CapsuleTtsService.notify(requestId, TtsPlaybackState.ERROR, `语音服务错误 ${code}：${message}`);
            CapsuleTtsService.clearActive(requestId);
          }
        });
        CapsuleTtsService.engine = engine;
        return engine;
      } catch (error) {
        lastError = CapsuleTtsService.errorMessage(error);
        console.error(`[CapsuleTts] Chinese engine candidate ${i} unavailable: ${lastError}`);
      }
    }
    throw new Error(lastError.length > 0 ? lastError : '未找到可用的中文音色');
  }

  private static notify(requestId: string, state: TtsPlaybackState, message: string): void {
    if (requestId !== CapsuleTtsService.activeRequestId) return;
    CapsuleTtsService.activeListener?.(state, message);
  }

  private static clearActive(requestId: string): void {
    if (requestId !== CapsuleTtsService.activeRequestId) return;
    CapsuleTtsService.activeRequestId = '';
    CapsuleTtsService.activeListener = undefined;
  }

  private static errorMessage(error: Object): string {
    try { return JSON.stringify(error); } catch (_) { return '语音服务不可用'; }
  }
}
