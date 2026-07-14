# 记忆电台 · Memory Radio — 开发指导文档

> **适用平台**：HarmonyOS NEXT (API 14+, HarmonyOS 5.0.2)  
> **目标项目**：植忆 (com.example.date)  
> **文档用途**：指导 AI 按照官方规范完成功能开发

---

## 一、功能概述

### 1.1 产品定义

一个沉浸式的全屏"电台模式"。App 进入深色全屏界面，像收听深夜电台一样，由 TTS 温柔女声 + AI 生成的 DJ 串词，将不同日期的记忆串联成一段情感叙述。背景有可选的环境音（雨声/壁炉/海浪），当前记忆的模糊照片缓慢轮播。

### 1.2 核心玩法

| 动作 | 描述 |
|------|------|
| **选择频道** | 5 个电台频道：随机漫步 / 阳光电台（只有开心的记忆）/ 时光倒流（从近到远）/ 影像馆（有照片的记忆）/ 深夜树洞（低落&疲惫） |
| **收听体验** | AI DJ 在记忆之间生成转场词 → TTS 朗读记忆内容 → 环境音持续播放 → 模糊照片背景 |
| **播放控制** | 上一段 / 播放暂停 / 下一段，锁屏后继续播放（后台长时任务 + AVSession） |
| **切歌** | 左右滑动手势切换记忆，像切歌一样自然 |
| **收藏到歌单** | 听到触动的记忆点 ❤️ 收藏，生成"记忆歌单"可回听 |
| **耳机线控** | 蓝牙/有线耳机按键控制：单击暂停、双击下一段、三击上一段 |

### 1.3 鸿蒙能力运用

| 能力 | 用途 | 对应 Kit/API |
|------|------|-------------|
| **TTS 语音朗读** | 核心能力：阅读记忆内容 + AI 转场词 | `@kit.CoreSpeechKit` |
| **后台长时任务** | 锁屏后继续播放，应用不被挂起 | `@kit.BackgroundTasksKit` |
| **AVSession 媒体会话** | 播控中心显示当前记忆、锁屏卡片、耳机线控 | `@kit.AVSessionKit` |
| **环境音播放** | 雨声/壁炉/海浪循环播放，与 TTS 走不同音频通道 | `@ohos.multimedia.audio` |
| **WantAgent** | 锁屏通知点击恢复前台 | `@kit.AbilityKit` |
| **模糊背景** | 当前记忆照片模糊后作为全屏背景 | `@kit.ArkUI` 滤镜效果 |

---

## 二、架构设计

### 2.1 新增文件清单

```
entry/src/main/ets/
├── models/
│   ├── RadioChannel.ets              ← 电台频道数据模型
│   ├── MemoryTrack.ets               ← 记忆音轨（记忆 + AI转场词）
│   └── RadioPlaylist.ets             ← 收藏歌单模型
├── viewmodels/
│   ├── RadioViewModel.ets            ← 电台核心逻辑（播放控制/频道/歌单）
│   └── RadioTransitionAI.ets         ← AI 转场词生成器
├── services/
│   ├── AmbientSoundService.ets       ← 环境音管理
│   └── RadioSessionService.ets       ← AVSession 媒体会话管理
├── components/
│   ├── AmbientBlurBackground.ets     ← 模糊照片背景组件
│   ├── RadioPlayerBar.ets            ← 播放控制条
│   └── RadioChannelSelector.ets      ← 频道选择器
└── pages/
    └── MemoryRadioPage.ets           ← 电台沉浸页面
```

### 2.2 修改文件清单

```
entry/src/main/ets/
├── constants/AppRoutes.ets           ← 新增 MEMORY_RADIO 路由
└── entry/src/main/module.json5       ← 新增后台长时任务权限 + backgroundModes
```

---

## 三、数据模型

### 3.1 RadioChannel.ets

```typescript
// models/RadioChannel.ets

import { Memory } from './Memory';

/**
 * 电台频道数据模型
 */
export class RadioChannel {
  /** 频道唯一 ID */
  id: string = '';

  /** 频道名称 */
  name: string = '';

  /** 频道图标 */
  icon: string = '';

  /** 频道描述 */
  description: string = '';

  /** 记忆筛选器：接收全部记忆，返回筛选/排序后的记忆列表 */
  filterFn: (memories: Memory[]) => Memory[] = (m) => m;

  constructor(
    id: string, name: string, icon: string, description: string,
    filterFn: (memories: Memory[]) => Memory[]
  ) {
    this.id = id;
    this.name = name;
    this.icon = icon;
    this.description = description;
    this.filterFn = filterFn;
  }
}

/**
 * 预设电台频道
 */
export class RadioChannels {
  /**
   * 全部 5 个频道
   *
   * 每个频道通过 filterFn 定义记忆的筛选和排序逻辑
   */
  static readonly LIST: RadioChannel[] = [
    new RadioChannel(
      'random', '随机漫步', '🎲',
      '随机播放，像在树林里散步，不知道下一片叶子会是什么颜色',
      (memories: Memory[]) => {
        // Fisher-Yates 洗牌
        const arr = memories.slice();
        for (let i = arr.length - 1; i > 0; i--) {
          const j = Math.floor((i + 1) * (Date.now() % 10000 / 10000)) % (i + 1);
          [arr[i], arr[j]] = [arr[j], arr[i]];
        }
        return arr;
      }
    ),
    new RadioChannel(
      'happy', '阳光电台', '☀️',
      '只有开心的记忆，用温暖照亮此刻',
      (memories: Memory[]) => memories.filter(m => m.mood === 'happy' || m.mood === 'excited')
    ),
    new RadioChannel(
      'timeline', '时光倒流', '⏪',
      '从最近的记忆开始，慢慢走回过去',
      (memories: Memory[]) => memories.slice().sort((a, b) =>
        b.createdAt.localeCompare(a.createdAt)
      )
    ),
    new RadioChannel(
      'photo', '影像馆', '📷',
      '只播放那些留下了照片的瞬间',
      (memories: Memory[]) => memories.filter(m => m.imageUrl.length > 0)
    ),
    new RadioChannel(
      'night', '深夜树洞', '🌙',
      '适合夜晚：安静、思考、偶尔的低落',
      (memories: Memory[]) => memories.filter(m => m.mood === 'sad' || m.mood === 'tired' || m.mood === 'calm')
    )
  ];

  /** 根据 ID 查找频道 */
  static find(id: string): RadioChannel {
    return RadioChannels.LIST.find(c => c.id === id) ?? RadioChannels.LIST[0];
  }
}
```

### 3.2 MemoryTrack.ets

```typescript
// models/MemoryTrack.ets

import { Memory } from './Memory';

/**
 * 记忆音轨
 *
 * 一条音轨 = 一条记忆 + AI 生成的 DJ 转场词。
 * 转场词在切换音轨时由 AI 异步生成，TTS 先朗读转场词再朗读记忆内容。
 */
export class MemoryTrack {
  /** 对应的记忆 */
  memory: Memory;

  /** AI 生成的 DJ 转场词（如 "接下来，是三年前的一个雨天…"） */
  transitionScript: string = '';

  /** 转场词是否已生成 */
  transitionReady: boolean = false;

  /** 是否已被收藏 */
  isFavorited: boolean = false;

  /** 在播放列表中的序号（从 0 开始） */
  index: number = 0;

  constructor(memory: Memory, index: number = 0) {
    this.memory = memory;
    this.index = index;
  }

  /**
   * 构建 TTS 朗读文本
   *
   * 格式：[转场词] + [停顿] + [记忆内容] + [停顿] + [日期+心情标注]
   * 使用 [pN] 标记控制停顿节奏
   */
  buildTtsText(): string {
    const parts: string[] = [];

    // 转场词
    if (this.transitionReady && this.transitionScript.length > 0) {
      parts.push(`${this.transitionScript}[p800]`);
    }

    // 记忆正文（去除 emoji 避免 TTS 异常）
    const cleanContent = this.memory.content.replace(
      /[\u{1F600}-\u{1F6FF}\u{1F300}-\u{1F5FF}★☆✦◌☀☂☾♧⌂◎◇]/gu, ''
    );
    parts.push(cleanContent);

    // 日期标注
    parts.push(`[p600]${this.memory.date}[p200]。`);

    return parts.join('');
  }
}
```

### 3.3 RadioPlaylist.ets

```typescript
// models/RadioPlaylist.ets

import { MemoryTrack } from './MemoryTrack';

/**
 * 收藏歌单
 *
 * 用户在电台中点击 ❤️ 收藏的记忆，聚合为可回放的歌单。
 * 数据持久化到 preferences（本地）。
 */
export class RadioPlaylist {
  /** 歌单名称 */
  name: string = '';

  /** 收藏的音轨列表 */
  tracks: MemoryTrack[] = [];

  /** 创建时间（ISO 8601） */
  createdAt: string = '';

  constructor(name: string = '我的记忆歌单', tracks: MemoryTrack[] = []) {
    this.name = name;
    this.tracks = tracks;
    this.createdAt = new Date().toISOString();
  }
}
```

---

## 四、服务层

### 4.1 AmbientSoundService.ets — 环境音管理服务

```typescript
// services/AmbientSoundService.ets

import { audio } from '@kit.AudioKit';

/**
 * 环境音类型
 */
export enum AmbientSound {
  NONE = 'none',
  RAIN = 'rain',
  FIREPLACE = 'fireplace',
  OCEAN = 'ocean',
  FOREST = 'forest'
}

/**
 * 环境音服务
 *
 * 使用 @ohos.multimedia.audio 的 AudioRenderer 循环播放环境音。
 * 环境音和 TTS 走不同的音频流，系统自动混音。
 *
 * 官方参考：
 *   https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/audio-renderer
 *
 * 注意：实际实现需要预置音频资源文件（.ogg/.mp3），存放在 rawfile 目录。
 * 以下代码展示核心 API 调用流程，音频文件路径需根据实际资源调整。
 */
export class AmbientSoundService {
  private static instance: AmbientSoundService;
  private currentSound: AmbientSound = AmbientSound.NONE;
  private volume: number = 0.3;  // 默认 30% 音量（环境音不抢 TTS 的风头）

  /** 音频资源文件映射（需在 entry/src/main/resources/rawfile/ 中放置对应文件） */
  private static readonly SOUND_FILES: Record<string, string> = {
    'rain': 'ambient_rain.ogg',
    'fireplace': 'ambient_fireplace.ogg',
    'ocean': 'ambient_ocean.ogg',
    'forest': 'ambient_forest.ogg'
  };

  static getInstance(): AmbientSoundService {
    if (!AmbientSoundService.instance) {
      AmbientSoundService.instance = new AmbientSoundService();
    }
    return AmbientSoundService.instance;
  }

  /**
   * 切换到指定环境音
   *
   * 使用淡入淡出避免突兀切换：旧音淡出 → 新音淡入
   *
   * @param sound    目标环境音
   * @param fadeMs   淡入淡出时长（ms），默认 800ms
   */
  async switchTo(sound: AmbientSound, fadeMs: number = 800): Promise<void> {
    if (sound === this.currentSound) return;

    // 1. 淡出当前环境音
    if (this.currentSound !== AmbientSound.NONE) {
      await this.fadeOut(fadeMs);
    }

    // 2. 切换
    this.currentSound = sound;

    // 3. 淡入新环境音
    if (sound !== AmbientSound.NONE) {
      await this.fadeIn(sound, fadeMs);
    }
  }

  /**
   * 设置音量
   *
   * @param vol 音量值 [0, 1]
   */
  setVolume(vol: number): void {
    this.volume = Math.max(0, Math.min(1, vol));
    // 更新 AudioRenderer 音量
  }

  /** 获取当前环境音 */
  getCurrent(): AmbientSound { return this.currentSound; }

  /** 停止所有环境音 */
  async stop(): Promise<void> {
    await this.switchTo(AmbientSound.NONE);
  }

  /** 销毁服务 */
  destroy(): void {
    this.stop();
  }

  // ── 内部方法 ──

  private async fadeOut(ms: number): Promise<void> {
    // 实现：逐步降低 AudioRenderer 音量至 0，然后 stop
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  private async fadeIn(sound: AmbientSound, ms: number): Promise<void> {
    // 实现：start AudioRenderer → 逐步提升音量至 this.volume
    const fileKey = AmbientSoundService.SOUND_FILES[sound];
    if (!fileKey) return;
    console.info(`[Ambient] 开始播放: ${sound} (${fileKey})`);
    return new Promise<void>((resolve) => {
      setTimeout(() => resolve(), ms);
    });
  }

  /**
   * 获取所有可用的环境音列表（供 UI 展示）
   */
  static getAvailableSounds(): { key: AmbientSound; label: string; icon: string }[] {
    return [
      { key: AmbientSound.NONE, label: '无', icon: '🔇' },
      { key: AmbientSound.RAIN, label: '雨声', icon: '🌧️' },
      { key: AmbientSound.FIREPLACE, label: '壁炉', icon: '🔥' },
      { key: AmbientSound.OCEAN, label: '海浪', icon: '🌊' },
      { key: AmbientSound.FOREST, label: '森林', icon: '🌲' }
    ];
  }
}
```

### 4.2 RadioSessionService.ets — AVSession 媒体会话管理

```typescript
// services/RadioSessionService.ets

import { avSession } from '@kit.AVSessionKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { Context } from '@kit.AbilityKit';

/**
 * 电台媒体会话服务
 *
 * 管理 AVSession 的生命周期，实现：
 *   - 播控中心（通知栏/锁屏）显示当前记忆
 *   - 耳机线控（播放/暂停/上下曲）
 *   - 后台长时任务申请与取消
 *
 * 官方参考：
 *   - AVSession 提供方开发指南:
 *     https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/using-avsession-developer-V5
 *   - 长时任务开发指南:
 *     https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V14/continuous-task-V14
 *
 * 关键约束：
 *   - 一个 UIAbility 只能创建一个 AVSession，重复创建会失败
 *   - 使用 audioPlayback 必须接入 AVSession，否则系统会取消长时任务
 *   - 暂停时必须取消长时任务，恢复时重新申请
 */
export class RadioSessionService {
  private session: avSession.AVSession | null = null;
  private context: Context | null = null;

  // 回调：播控中心按钮被点击时触发
  onPlay: () => void = () => {};
  onPause: () => void = () => {};
  onNext: () => void = () => {};
  onPrevious: () => void = () => {};
  onFavorite: () => void = () => {};

  /**
   * 创建并激活 AVSession
   *
   * @param context 应用上下文
   */
  async create(context: Context): Promise<void> {
    this.context = context;

    // 步骤 1：先注册播控命令监听
    this.session = await avSession.createAVSession(context, 'MemoryRadio', 'audio');

    // 步骤 2：设置监听
    this.session.on('play', () => this.onPlay());
    this.session.on('pause', () => this.onPause());
    this.session.on('stop', () => { /* 停止电台 */ });
    this.session.on('playNext', () => this.onNext());
    this.session.on('playPrevious', () => this.onPrevious());
    this.session.on('toggleFavorite', () => this.onFavorite());
    this.session.on('seek', (time: number) => {
      console.info(`[RadioSession] 快进/快退: ${time}ms`);
    });

    // 步骤 3：激活会话
    await this.session.activate();

    console.info('[RadioSession] AVSession 创建并激活');
  }

  /**
   * 更新播控中心显示的元数据
   *
   * @param trackTitle  当前记忆标题（取前 30 字）
   * @param trackArtist  记忆作者
   * @param imageUrl     记忆照片 URL（可选，作为封面）
   * @param duration     估计朗读时长（ms）
   * @param currentIndex 当前音轨序号
   * @param totalCount   总音轨数
   */
  async updateMetadata(
    trackTitle: string, trackArtist: string,
    imageUrl: string = '', duration: number, currentIndex: number, totalCount: number
  ): Promise<void> {
    if (!this.session) return;

    const metadata: avSession.AVMetadata = {
      assetId: `track_${currentIndex}`,
      title: trackTitle.length > 30 ? trackTitle.substring(0, 30) + '…' : trackTitle,
      artist: trackArtist,
      author: `第 ${currentIndex + 1}/${totalCount} 段记忆`,
      duration: duration,
      // 如果有照片，设置为封面图
      ...(imageUrl.length > 0 ? { mediaImage: imageUrl } : {}),
      skipIntervals: avSession.SkipIntervals.SECONDS_10
    };

    await this.session.setAVMetadata(metadata);
  }

  /**
   * 更新播放状态
   */
  async updatePlayState(state: avSession.PlaybackState, elapsedMs: number = 0): Promise<void> {
    if (!this.session) return;

    const playbackState: avSession.AVPlaybackState = {
      state: state,
      position: {
        elapsedTime: elapsedMs,
        updateTime: Date.now()
      },
      speed: 1.0
    };

    await this.session.setAVPlaybackState(playbackState);
  }

  /**
   * 申请后台长时任务（开始播放时调用）
   *
   * 必须同时满足三个条件：
   *   1. module.json5 中配置 backgroundModes: ["audioPlayback"]
   *   2. 申请 ohos.permission.KEEP_BACKGROUND_RUNNING 权限
   *   3. 已创建并激活 AVSession
   */
  async requestBackgroundTask(): Promise<void> {
    if (!this.context) return;

    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: 'com.example.date',
        abilityName: 'EntryAbility'
      }],
      actionType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
      actionFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    };

    try {
      const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);
      await backgroundTaskManager.startBackgroundRunning(
        this.context,
        backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK,
        agent
      );
      console.info('[RadioSession] 后台长时任务已申请');
    } catch (err) {
      console.error(`[RadioSession] 长时任务申请失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 取消后台长时任务（暂停/停止时调用）
   */
  async cancelBackgroundTask(): Promise<void> {
    if (!this.context) return;
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      console.info('[RadioSession] 后台长时任务已取消');
    } catch (err) {
      console.error(`[RadioSession] 长时任务取消失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 销毁 AVSession
   */
  async destroy(): Promise<void> {
    if (this.session) {
      this.session.off('play');
      this.session.off('pause');
      this.session.off('playNext');
      this.session.off('playPrevious');
      this.session.off('toggleFavorite');
      await this.session.destroy();
      this.session = null;
      console.info('[RadioSession] AVSession 已销毁');
    }
  }
}
```

---

## 五、ViewModel 层

### 5.1 RadioViewModel.ets — 电台核心逻辑

```typescript
// viewmodels/RadioViewModel.ets

import { Memory } from '../models/Memory';
import { MemoryTrack } from '../models/MemoryTrack';
import { RadioChannel, RadioChannels } from '../models/RadioChannel';
import { RadioPlaylist } from '../models/RadioPlaylist';
import { MemoryViewModel } from './MemoryViewModel';
import { RadioTransitionAI } from './RadioTransitionAI';
import { Context } from '@kit.AbilityKit';
import { TtsService, TtsState } from '../services/TtsService';

/**
 * 电台播放状态
 */
export enum RadioPlayState {
  IDLE = 'idle',       // 未开始
  PLAYING = 'playing', // 播放中
  PAUSED = 'paused',   // 暂停
  TRANSITIONING = 'transitioning'  // 正在生成转场词并切换
}

/**
 * 电台 ViewModel
 *
 * 负责：
 *   - 频道切换 → 重新生成播放列表
 *   - 播放控制：播放/暂停/上一曲/下一曲
 *   - 转场词生成（异步 AI）
 *   - 收藏管理
 */
export class RadioViewModel {
  private readonly memoryVm: MemoryViewModel = new MemoryViewModel();
  private readonly tts: TtsService = TtsService.getInstance();

  /** 当前频道 */
  currentChannel: RadioChannel = RadioChannels.LIST[0];

  /** 当前频道下的播放列表（音轨数组） */
  tracks: MemoryTrack[] = [];

  /** 当前播放的音轨索引 */
  currentIndex: number = -1;

  /** 播放状态 */
  playState: RadioPlayState = RadioPlayState.IDLE;

  /** 收藏歌单 */
  playlist: RadioPlaylist = new RadioPlaylist();

  /** 状态变化回调（供 UI 刷新） */
  onStateChange: (() => void) | null = null;

  /**
   * 初始化：加载全部记忆并生成初始播放列表
   */
  async initialize(context: Context): Promise<void> {
    const memories = await this.memoryVm.listMemories(context);
    this.buildTrackList(memories);
  }

  /**
   * 切换频道
   */
  switchChannel(channelId: string, allMemories: Memory[]): void {
    this.stop();
    this.currentChannel = RadioChannels.find(channelId);
    this.buildTrackList(allMemories);
    this.notifyStateChange();
  }

  /**
   * 开始播放（从开头或从指定索引）
   */
  async play(fromIndex?: number): Promise<void> {
    if (this.tracks.length === 0) return;

    if (fromIndex !== undefined) {
      this.currentIndex = fromIndex;
    } else if (this.currentIndex < 0) {
      this.currentIndex = 0;
    }

    const track = this.tracks[this.currentIndex];
    if (!track) return;

    // 如果转场词未生成，异步生成
    if (!track.transitionReady) {
      this.playState = RadioPlayState.TRANSITIONING;
      this.notifyStateChange();

      try {
        track.transitionScript = await RadioTransitionAI.generate(
          track,
          this.getPreviousTrack()
        );
        track.transitionReady = true;
      } catch (_err) {
        // 转场词生成失败，直接朗读记忆内容
        track.transitionReady = true;
      }
    }

    // 确保 TTS 引擎已初始化
    try {
      await this.tts.init();
    } catch (_) { /* 已初始化 */ }

    // 通过 TTS 朗读
    const text = track.buildTtsText();
    this.tts.speak(text);

    this.playState = RadioPlayState.PLAYING;
    this.notifyStateChange();
  }

  /** 暂停 */
  pause(): void {
    this.tts.stop();
    this.playState = RadioPlayState.PAUSED;
    this.notifyStateChange();
  }

  /** 停止 */
  stop(): void {
    this.tts.stop();
    this.playState = RadioPlayState.IDLE;
    this.currentIndex = -1;
    this.notifyStateChange();
  }

  /** 下一段 */
  async next(): Promise<void> {
    if (this.currentIndex >= this.tracks.length - 1) {
      // 已是最后一段，停止播放
      this.stop();
      return;
    }
    this.currentIndex++;
    await this.play();
  }

  /** 上一段 */
  async previous(): Promise<void> {
    if (this.currentIndex <= 0) {
      // 已是最前，重新播当前
      await this.play(0);
      return;
    }
    this.currentIndex--;
    await this.play();
  }

  /** 获取当前音轨 */
  getCurrentTrack(): MemoryTrack | undefined {
    if (this.currentIndex < 0 || this.currentIndex >= this.tracks.length) return undefined;
    return this.tracks[this.currentIndex];
  }

  /** 切换当前音轨的收藏状态 */
  toggleFavorite(): void {
    const track = this.getCurrentTrack();
    if (!track) return;
    track.isFavorited = !track.isFavorited;
    if (track.isFavorited) {
      this.playlist.tracks.push(track);
    } else {
      this.playlist.tracks = this.playlist.tracks.filter(t => t.memory.id !== track.memory.id);
    }
    this.notifyStateChange();
  }

  /** 获取频道列表 */
  getChannels(): RadioChannel[] {
    return RadioChannels.LIST;
  }

  // ── 内部方法 ──

  /** 根据频道的 filterFn 构建播放列表 */
  private buildTrackList(memories: Memory[]): void {
    const filtered = this.currentChannel.filterFn(memories);
    this.tracks = filtered.map((m, i) => new MemoryTrack(m, i));
    this.currentIndex = -1;
  }

  private getPreviousTrack(): MemoryTrack | undefined {
    if (this.currentIndex <= 0) return undefined;
    return this.tracks[this.currentIndex - 1];
  }

  private notifyStateChange(): void {
    if (this.onStateChange) this.onStateChange();
  }
}
```

### 5.2 RadioTransitionAI.ets — AI 转场词生成器

```typescript
// viewmodels/RadioTransitionAI.ets

import { MemoryTrack } from '../models/MemoryTrack';
import { AgentRepository } from '../repositories/AgentRepository';
import { Context } from '@kit.AbilityKit';

/**
 * AI DJ 转场词生成器
 *
 * 在记忆之间生成情感化的转场词，让电台听起来像有 DJ 在主持。
 *
 * 复用项目已有的 AgentRepository（参见 AgentViewModel、AgentChat），
 * 通过同一后端 AI 接口（/api/agent/rememberer/chat）生成转场词。
 *
 * 生成策略：
 *   - 第一条记忆：无转场词（直接开始）
 *   - 后续记忆：根据当前记忆和上一条记忆的上下文生成一句 1~2 行的话
 *   - AI 提示词由本方法构建，确保输出风格一致
 */
export class RadioTransitionAI {
  /**
   * 为当前音轨生成转场词
   *
   * @param current  当前要播放的音轨
   * @param previous 上一首音轨（undefined 表示是第一首）
   * @returns 转场词文本
   */
  static async generate(current: MemoryTrack, previous?: MemoryTrack): Promise<string> {
    // 第一首记忆不需要转场词
    if (!previous) return '';

    // 构建 AI 提示词
    const prompt = RadioTransitionAI.buildPrompt(current, previous);

    try {
      // 复用 Agent API（需要 context，从全局获取或传入）
      const resp = await RadioTransitionAI.callAgent(prompt);
      // 清理 AI 输出：去除引号、截取第一行
      return RadioTransitionAI.cleanResponse(resp);
    } catch (_err) {
      // AI 不可用时返回简单默认转场词
      return RadioTransitionAI.fallbackTransition(current, previous);
    }
  }

  /**
   * 构建 AI 提示词
   *
   * 要求 AI 以温柔、文艺的 DJ 口吻生成转场词
   */
  private static buildPrompt(current: MemoryTrack, previous: MemoryTrack): string {
    const prevContent = previous.memory.content.length > 50
      ? previous.memory.content.substring(0, 50) + '…'
      : previous.memory.content;
    const currContent = current.memory.content.length > 50
      ? current.memory.content.substring(0, 50) + '…'
      : current.memory.content;

    const moodLabels: Record<string, string> = {
      'calm': '平静', 'happy': '开心', 'excited': '雀跃', 'sad': '低落', 'tired': '疲惫'
    };
    const prevMood = moodLabels[previous.memory.mood] ?? '平静';
    const currMood = moodLabels[current.memory.mood] ?? '平静';

    return `你是深夜电台的 DJ，正在朗读一个人的记忆日记。

上一段记忆（${previous.memory.date}，心情${prevMood}）：
"${prevContent}"

接下来要朗读的记忆（${current.memory.date}，心情${currMood}）：
"${currContent}"

请用一句话转场（中文，温柔文艺风格，不超过40个字），自然地连接这两段记忆。
不要用引号包裹，只输出转场词本身。`;
  }

  /**
   * 调用 Agent API
   */
  private static async callAgent(prompt: string): Promise<string> {
    // 注意：需要使用有效的 Context 实例
    // 这里返回示例格式，实际调用：
    // const repo = new AgentRepository();
    // const result = await repo.chat(context, 0, prompt);
    // return result.data?.answer ?? '';
    return '';
  }

  /**
   * 清理 AI 输出
   */
  private static cleanResponse(raw: string): string {
    return raw
      .replace(/^["「『]/g, '')   // 去除开头引号
      .replace(/["」』]$/g, '')    // 去除结尾引号
      .replace(/\n/g, ' ')        // 换行转空格
      .trim();
  }

  /**
   * AI 不可用时的降级转场词（使用固定模板，保证体验不中断）
   */
  private static fallbackTransition(current: MemoryTrack, previous: MemoryTrack): string {
    const dayDiff = Math.floor(
      (new Date(current.memory.date).getTime() - new Date(previous.memory.date).getTime()) / 86400000
    );

    if (dayDiff === 0) return '同一天，还有这段记忆。';
    if (dayDiff === 1) return '第二天。';
    if (dayDiff < 7) return `${dayDiff}天后。`;
    if (dayDiff < 30) return `过了${Math.floor(dayDiff / 7)}周。`;
    if (dayDiff < 365) return `时间来到${Math.floor(dayDiff / 30)}个月后。`;
    return `时光来到${current.memory.date}。`;
  }
}
```

---

## 六、组件

### 6.1 AmbientBlurBackground.ets — 模糊照片背景

```typescript
// components/AmbientBlurBackground.ets

import { MemoryTrack } from '../models/MemoryTrack';

/**
 * 模糊照片背景组件
 *
 * 将当前记忆的照片做模糊处理，作为电台的全屏背景。
 * 使用 ArkUI 的 .blur() 滤镜实现高斯模糊。
 * 多张照片之间使用 CrossFade 过渡（3 秒淡入淡出）。
 */
@Component
export struct AmbientBlurBackground {
  /** 当前播放的音轨 */
  @Prop currentTrack: MemoryTrack | undefined = undefined;
  /** 上一张照片 URL（用于过渡） */
  @State previousImageUrl: string = '';
  /** 当前照片 URL */
  @State currentImageUrl: string = '';
  /** 是否在过渡中 */
  @State transitioning: boolean = false;

  /**
   * 监听 currentTrack 变化，触发照片过渡
   */
  @Watch('onTrackChanged')
  @Prop trackImageUrl: string = '';

  onTrackChanged(): void {
    if (this.trackImageUrl.length === 0) return;
    if (this.trackImageUrl === this.currentImageUrl) return;

    this.previousImageUrl = this.currentImageUrl;
    this.currentImageUrl = this.trackImageUrl;
    this.transitioning = true;

    // 过渡动画结束后清理旧照片
    setTimeout(() => {
      this.transitioning = false;
      this.previousImageUrl = '';
    }, 3000);
  }

  build() {
    Stack() {
      // 底层：纯色暗背景（无照片时显示）
      Column()
        .width('100%').height('100%')
        .backgroundColor('#0F0F14')

      // 旧照片（淡出）
      if (this.transitioning && this.previousImageUrl.length > 0) {
        Image(this.previousImageUrl)
          .width('100%').height('100%')
          .objectFit(ImageFit.Cover)
          .blur(40)
          .opacity(0.4)
          .animation({ duration: 3000, curve: Curve.EaseOut })
      }

      // 当前照片（模糊 + 暗色叠加）
      if (this.currentImageUrl.length > 0) {
        Image(this.currentImageUrl)
          .width('100%').height('100%')
          .objectFit(ImageFit.Cover)
          .blur(40)                             // 40px 高斯模糊
          .brightness(0.35)                     // 降低亮度，营造夜间氛围
          .opacity(this.transitioning ? 0 : 0.5)
          .animation({ duration: 3000, curve: Curve.EaseIn })
      }

      // 暗色渐变遮罩（从顶部深黑到底部微亮）
      Column()
        .width('100%').height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [
            ['#0F0F14', 0],
            ['#0F0F14A0', 0.4],
            ['#0F0F1440', 0.75],
            ['#0F0F1400', 1]
          ]
        })
    }
    .width('100%').height('100%')
  }
}
```

### 6.2 RadioPlayerBar.ets — 播放控制条

```typescript
// components/RadioPlayerBar.ets

import { RadioPlayState } from '../viewmodels/RadioViewModel';
import { MemoryTrack } from '../models/MemoryTrack';

/**
 * 电台播放控制条
 *
 * 显示当前记忆信息 + 播放/暂停/上一曲/下一曲/收藏按钮。
 * 支持左右滑动手势切歌。
 */
@Component
export struct RadioPlayerBar {
  @Prop playState: RadioPlayState = RadioPlayState.IDLE;
  @Prop currentTrack: MemoryTrack | undefined = undefined;
  @Prop totalTracks: number = 0;
  @Prop currentIndex: number = -1;

  onPlay: () => void = () => {};
  onPause: () => void = () => {};
  onNext: () => void = () => {};
  onPrevious: () => void = () => {};
  onFavorite: () => void = () => {};

  /** 滑动手势起始 X 坐标 */
  private swipeStartX: number = 0;

  build() {
    Column({ space: 12 }) {
      // 进度指示器
      if (this.playState === RadioPlayState.PLAYING) {
        Row({ space: 6 }) {
          ForEach(Array.from({ length: Math.min(this.totalTracks, 20) }), (_: undefined, i: number) => {
            Row()
              .width('100%').height(2)
              .borderRadius(1)
              .backgroundColor(i <= this.currentIndex ? '#FFFFFF80' : '#FFFFFF18')
          })
        }
        .width('100%')
      }

      // 当前记忆信息
      if (this.currentTrack) {
        Column({ space: 6 }) {
          Text(this.currentTrack.memory.date)
            .fontSize(12).fontColor('#FFFFFF60')
          Text(
            this.currentTrack.memory.content.length > 40
              ? this.currentTrack.memory.content.substring(0, 40) + '…'
              : this.currentTrack.memory.content
          )
            .fontSize(17).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
            .maxLines(2).textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
          if (this.currentTrack.transitionScript.length > 0) {
            Text(this.currentTrack.transitionScript)
              .fontSize(12).fontColor('#FFFFFF50')
              .maxLines(1).textAlign(TextAlign.Center)
          }
        }
        .width('100%').alignItems(HorizontalAlign.Center)
      }

      // 播放控制按钮
      Row({ space: 32 }) {
        // 上一曲
        Text('⏮').fontSize(22).fontColor('#FFFFFF80')
          .onClick(() => { this.onPrevious(); })

        // 播放/暂停
        Stack() {
          Circle().width(64).height(64).fill('#FFFFFF18')
          Text(
            this.playState === RadioPlayState.PLAYING ? '⏸' :
            this.playState === RadioPlayState.TRANSITIONING ? '⏳' : '▶️'
          )
            .fontSize(26)
        }
        .onClick(() => {
          if (this.playState === RadioPlayState.PLAYING) this.onPause();
          else this.onPlay();
        })

        // 下一曲
        Text('⏭').fontSize(22).fontColor('#FFFFFF80')
          .onClick(() => { this.onNext(); })
      }
      .justifyContent(FlexAlign.Center).width('100%')

      // 底部：频道 + 环境音 + 收藏
      Row() {
        Text(this.currentTrack?.memory.authorName ?? '')
          .fontSize(11).fontColor('#FFFFFF40')
        Blank()
        // 收藏按钮
        Text(this.currentTrack?.isFavorited ? '❤️' : '🤍')
          .fontSize(18)
          .onClick(() => { this.onFavorite(); })
      }
      .width('100%')
    }
    .width('100%').padding(20).borderRadius({ topLeft: 24, topRight: 24 })
    .backgroundColor('#1A1A22')
    .gesture(
      // 左右滑动手势切歌
      PanGesture({ direction: PanDirection.Horizontal, distance: 60 })
        .onActionStart((event: GestureEvent) => {
          this.swipeStartX = event.offsetX;
        })
        .onActionEnd((event: GestureEvent) => {
          const deltaX = event.offsetX - this.swipeStartX;
          if (Math.abs(deltaX) > 50) {
            if (deltaX < 0) this.onNext();
            else this.onPrevious();
          }
        })
    )
  }
}
```

---

## 七、页面

### 7.1 MemoryRadioPage.ets — 电台沉浸页

```typescript
// pages/MemoryRadioPage.ets

import { Memory } from '../models/Memory';
import { MemoryTrack } from '../models/MemoryTrack';
import { RadioChannel } from '../models/RadioChannel';
import { RadioPlayState, RadioViewModel } from '../viewmodels/RadioViewModel';
import { AmbientSoundService, AmbientSound } from '../services/AmbientSoundService';
import { RadioSessionService } from '../services/RadioSessionService';
import { MemoryViewModel } from '../viewmodels/MemoryViewModel';
import { AmbientBlurBackground } from '../components/AmbientBlurBackground';
import { RadioPlayerBar } from '../components/RadioPlayerBar';
import { StatePanel } from '../components/StatePanel';
import { avSession } from '@kit.AVSessionKit';

/**
 * 记忆电台沉浸页面
 *
 * 全屏暗色设计，提供类似深夜电台的沉浸式收听体验。
 * 核心体验链路：
 *   选择频道 → 生成播放列表 → 开始播放
 *   → TTS 朗读转场词 + 记忆内容（后台长时任务 + AVSession）
 *   → 模糊照片背景轮播 + 环境音
 *   → 播放控制（上一段/暂停/下一段/收藏）
 *   → 锁屏后继续播放
 */
@Entry
@Component
struct MemoryRadioPage {
  // 电台核心
  @State playState: RadioPlayState = RadioPlayState.IDLE;
  @State currentTrack: MemoryTrack | undefined = undefined;
  @State totalTracks: number = 0;
  @State currentIndex: number = -1;

  // 频道
  @State channels: RadioChannel[] = [];
  @State selectedChannelId: string = 'random';
  @State showChannelPicker: boolean = false;

  // 环境音
  @State ambientSound: AmbientSound = AmbientSound.NONE;
  @State showAmbientPicker: boolean = false;

  // 加载
  @State loading: boolean = false;
  @State errorMessage: string = '';

  // 全部记忆（频道切换时使用）
  private allMemories: Memory[] = [];

  private readonly radioVm: RadioViewModel = new RadioViewModel();
  private readonly memoryVm: MemoryViewModel = new MemoryViewModel();
  private readonly ambient: AmbientSoundService = AmbientSoundService.getInstance();
  private readonly sessionService: RadioSessionService = new RadioSessionService();

  aboutToAppear(): void {
    this.initialize();
  }

  private async initialize(): Promise<void> {
    this.loading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');

      // 加载全部记忆
      this.allMemories = await this.memoryVm.listMemories(context);
      if (this.allMemories.length === 0) {
        this.errorMessage = '还没有记忆可以收听，先记录一些吧';
        this.loading = false;
        return;
      }

      // 初始化频道列表
      this.channels = this.radioVm.getChannels();

      // 初始化电台 ViewModel
      await this.radioVm.initialize(context);

      // 初始化 AVSession + 注册回调
      await this.sessionService.create(context);
      this.sessionService.onPlay = () => this.handlePlay();
      this.sessionService.onPause = () => this.handlePause();
      this.sessionService.onNext = () => this.handleNext();
      this.sessionService.onPrevious = () => this.handlePrevious();
      this.sessionService.onFavorite = () => this.handleFavorite();

      // 监听状态变化
      this.radioVm.onStateChange = () => this.syncState();

      this.syncState();
    } catch (err) {
      this.errorMessage = '电台加载失败，请稍后重试';
    }
    this.loading = false;
  }

  /** 同步 ViewModel 状态到 @State */
  private syncState(): void {
    this.playState = this.radioVm.playState;
    this.currentTrack = this.radioVm.getCurrentTrack();
    this.totalTracks = this.radioVm.tracks.length;
    this.currentIndex = this.radioVm.currentIndex;
  }

  // ── 播放控制（同时更新 AVSession）──

  private async handlePlay(): Promise<void> {
    await this.radioVm.play();
    await this.sessionService.requestBackgroundTask();
    await this.sessionService.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PLAY);
    this.updateSessionMetadata();
  }

  private async handlePause(): Promise<void> {
    this.radioVm.pause();
    await this.sessionService.cancelBackgroundTask();
    await this.sessionService.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE);
  }

  private async handleNext(): Promise<void> {
    await this.radioVm.next();
    this.updateSessionMetadata();
    if (this.radioVm.playState === RadioPlayState.PLAYING) {
      await this.sessionService.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PLAY);
    }
  }

  private async handlePrevious(): Promise<void> {
    await this.radioVm.previous();
    this.updateSessionMetadata();
    if (this.radioVm.playState === RadioPlayState.PLAYING) {
      await this.sessionService.updatePlayState(avSession.PlaybackState.PLAYBACK_STATE_PLAY);
    }
  }

  private handleFavorite(): void {
    this.radioVm.toggleFavorite();
    this.syncState();
  }

  /** 更新 AVSession 元数据 */
  private updateSessionMetadata(): void {
    const track = this.radioVm.getCurrentTrack();
    if (!track) return;
    // 估算朗读时长：中文约 4 字/秒
    const estimatedDuration = Math.max(5000, track.memory.content.length * 250);
    this.sessionService.updateMetadata(
      track.memory.content,
      track.memory.authorName || '匿名',
      track.memory.imageUrl,
      estimatedDuration,
      this.radioVm.currentIndex,
      this.radioVm.tracks.length
    );
  }

  // ── 频道切换 ──

  private switchChannel(channelId: string): void {
    this.selectedChannelId = channelId;
    this.showChannelPicker = false;
    this.radioVm.switchChannel(channelId, this.allMemories);
    this.syncState();
    // 自动开始播放
    this.handlePlay();
  }

  // ── 环境音切换 ──

  private async switchAmbient(sound: AmbientSound): Promise<void> {
    this.ambientSound = sound;
    this.showAmbientPicker = false;
    await this.ambient.switchTo(sound);
  }

  // ── 生命周期 ──

  aboutToDisappear(): void {
    this.radioVm.stop();
    this.ambient.stop();
    this.sessionService.cancelBackgroundTask();
    this.sessionService.destroy();
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  // ========== UI ==========

  build() {
    Stack() {
      // 1. 模糊照片背景（全屏）
      AmbientBlurBackground({
        currentTrack: this.currentTrack,
        trackImageUrl: this.currentTrack?.memory.imageUrl ?? ''
      })

      // 2. 前景内容
      Column({ space: 0 }) {
        // 顶部导航
        Row() {
          Text('‹')
            .fontSize(34).fontWeight(FontWeight.Lighter)
            .fontColor('#FFFFFF')
            .onClick(() => { this.goBack(); })
          Blank()
          Text('📻')
            .fontSize(20)
        }
        .width('100%').padding({ left: 20, right: 20 })

        // 主内容区域
        if (this.loading) {
          StatePanel({ title: '正在调频…', description: '记忆电台马上开始', stateIcon: '📻' })
            .margin({ top: 120 })
        } else if (this.errorMessage.length > 0) {
          StatePanel({ title: '信号不太好', description: this.errorMessage, stateIcon: '📡' })
            .margin({ top: 120 })
        } else if (this.playState === RadioPlayState.IDLE) {
          // 初始状态：频道选择
          Column({ space: 16 }) {
            Text('记忆电台')
              .fontSize(34).fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('选择一个频道，开始收听')
              .fontSize(15).fontColor('#FFFFFF70')

            ForEach(this.channels, (ch: RadioChannel) => {
              Row({ space: 14 }) {
                Text(ch.icon).fontSize(28)
                Column({ space: 4 }) {
                  Text(ch.name).fontSize(18).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
                  Text(ch.description).fontSize(12).fontColor('#FFFFFF60').maxLines(2)
                }
                .alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%').padding(16).borderRadius(16)
              .backgroundColor(this.selectedChannelId === ch.id ? '#FFFFFF18' : '#FFFFFF08')
              .border({ width: 1, color: this.selectedChannelId === ch.id ? '#FFFFFF30' : '#FFFFFF08' })
              .onClick(() => { this.switchChannel(ch.id); })
            })

            Text('共 5 个频道 · 基于你的所有记忆')
              .fontSize(12).fontColor('#FFFFFF30')
          }
          .width('100%').padding({ left: 20, right: 20 })
          .margin({ top: 40 })
        } else {
          // 播放中/暂停状态：居中显示
          Blank()
        }

        Blank()

        // 3. 底部：频道 + 环境音 快捷切换
        if (this.playState !== RadioPlayState.IDLE) {
          Row({ space: 12 }) {
            // 频道切换
            Row({ space: 4 }) {
              Text(this.radioVm.currentChannel.icon).fontSize(14)
              Text(this.radioVm.currentChannel.name).fontSize(12).fontColor('#FFFFFF80')
            }
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(12).backgroundColor('#FFFFFF10')
            .onClick(() => { this.showChannelPicker = !this.showChannelPicker; })

            Blank()

            // 环境音切换
            Row({ space: 4 }) {
              Text('🔊').fontSize(12)
              Text(this.ambientSound === AmbientSound.NONE ? '环境音' : AmbientSoundService.getAvailableSounds().find(s => s.key === this.ambientSound)?.label ?? '')
                .fontSize(12).fontColor('#FFFFFF60')
            }
            .padding({ left: 10, right: 10, top: 5, bottom: 5 })
            .borderRadius(12).backgroundColor('#FFFFFF10')
            .onClick(() => { this.showAmbientPicker = !this.showAmbientPicker; })
          }
          .width('100%').padding({ left: 20, right: 20, bottom: 8 })
        }

        // 4. 播放控制条
        RadioPlayerBar({
          playState: this.playState,
          currentTrack: this.currentTrack,
          totalTracks: this.totalTracks,
          currentIndex: this.currentIndex,
          onPlay: () => { this.handlePlay(); },
          onPause: () => { this.handlePause(); },
          onNext: () => { this.handleNext(); },
          onPrevious: () => { this.handlePrevious(); },
          onFavorite: () => { this.handleFavorite(); }
        })
      }
      .width('100%').height('100%')

      // 5. 频道选择弹出层
      if (this.showChannelPicker) {
        Column() {
          Column({ space: 12 }) {
            Text('切换频道').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
            ForEach(this.channels, (ch: RadioChannel) => {
              Row({ space: 10 }) {
                Text(ch.icon).fontSize(22)
                Text(ch.name).fontSize(16)
                  .fontColor(this.selectedChannelId === ch.id ? '#FFFFFF' : '#FFFFFF70')
                Blank()
                if (this.selectedChannelId === ch.id) {
                  Text('✓').fontSize(16).fontColor('#CDA560')
                }
              }
              .width('100%').padding(12).borderRadius(12)
              .backgroundColor(this.selectedChannelId === ch.id ? '#FFFFFF15' : '#FFFFFF00')
              .onClick(() => { this.switchChannel(ch.id); })
            })
          }
          .width('80%').padding(20).borderRadius(20).backgroundColor('#2A2A35')
        }
        .width('100%').height('100%')
        .backgroundColor('#00000060').justifyContent(FlexAlign.Center)
        .onClick(() => { this.showChannelPicker = false; })
        .zIndex(100)
      }

      // 6. 环境音选择弹出层
      if (this.showAmbientPicker) {
        Column() {
          Column({ space: 12 }) {
            Text('环境音').fontSize(18).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
            ForEach(AmbientSoundService.getAvailableSounds(), (opt: { key: AmbientSound; label: string; icon: string }) => {
              Row({ space: 10 }) {
                Text(opt.icon).fontSize(22)
                Text(opt.label).fontSize(16)
                  .fontColor(this.ambientSound === opt.key ? '#FFFFFF' : '#FFFFFF70')
                Blank()
                if (this.ambientSound === opt.key) Text('✓').fontSize(16).fontColor('#CDA560')
              }
              .width('100%').padding(12).borderRadius(12)
              .backgroundColor(this.ambientSound === opt.key ? '#FFFFFF15' : '#FFFFFF00')
              .onClick(() => { this.switchAmbient(opt.key); })
            })
          }
          .width('80%').padding(20).borderRadius(20).backgroundColor('#2A2A35')
        }
        .width('100%').height('100%')
        .backgroundColor('#00000060').justifyContent(FlexAlign.Center)
        .onClick(() => { this.showAmbientPicker = false; })
        .zIndex(100)
      }
    }
    .width('100%').height('100%')
  }
}
```

---

## 八、module.json5 配置

### 8.1 后台长时任务权限 + backgroundModes

```json5
// entry/src/main/module.json5

{
  "module": {
    "abilities": [
      {
        "name": "EntryAbility",
        "launchType": "singleton",
        "backgroundModes": [
          "audioPlayback"              // ← 音频后台播放（必须）
        ],
        "srcEntry": "./ets/entryability/EntryAbility.ets"
        // ...
      }
    ],
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",   // ← 后台长时任务权限（必须）
        "reason": "$string:reason_background",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "always"
        }
      }
      // ... 已有权限
    ]
  }
}
```

### 8.2 AppRoutes.ets 追加

```typescript
static readonly MEMORY_RADIO: string = 'pages/MemoryRadioPage';
```

### 8.3 main_pages.json 追加

```json
"pages/MemoryRadioPage"
```

---

## 九、资源文件

以下环境音资源文件需要放置在 `entry/src/main/resources/rawfile/` 目录下：

| 文件名 | 内容 | 时长建议 |
|--------|------|----------|
| `ambient_rain.ogg` | 雨声白噪音 | 30 秒（循环播放） |
| `ambient_fireplace.ogg` | 壁炉燃烧声 | 30 秒（循环播放） |
| `ambient_ocean.ogg` | 海浪声 | 30 秒（循环播放） |
| `ambient_forest.ogg` | 森林虫鸣鸟叫 | 30 秒（循环播放） |

> 可使用免费音效网站（如 freesound.org）获取 CC0 授权的音频资源。

---

## 十、后端约定

电台功能**不强制需要新后端接口**，它复用现有的记忆列表 API：

| 使用方法 | API |
|----------|-----|
| 获取全部记忆 | `GET /api/memories`（已有） |
| AI 转场词生成 | `POST /api/agent/rememberer/chat`（已有） |
| 收藏歌单持久化 | 本地 preferences（无需后端） |

**可选后端增强**：为 AI 转场词增加专用 endpoint `POST /api/radio/transition`，接收 `{currentDate, currentContent, previousDate, previousContent}`，返回 `{transitionScript}`，减轻通用 Agent API 的负担。

---

## 十一、开发步骤（按顺序执行）

1. 创建 `RadioChannel.ets` + `MemoryTrack.ets` + `RadioPlaylist.ets` 数据模型
2. 创建 `RadioTransitionAI.ets` 转场词生成器
3. 创建 `AmbientSoundService.ets` 环境音服务（需准备音频资源文件）
4. 创建 `RadioSessionService.ets` AVSession 媒体会话管理
5. 创建 `RadioViewModel.ets` 电台核心逻辑编排
6. 创建 `AmbientBlurBackground.ets` 模糊照片背景组件
7. 创建 `RadioPlayerBar.ets` 播放控制条组件
8. 创建 `MemoryRadioPage.ets` 电台沉浸页面
9. 配置 `module.json5`（后台权限 + backgroundModes）
10. 配置路由（AppRoutes + main_pages.json）
11. 放置环境音音频资源文件
12. 真机测试（AVSession + 锁屏播放 + 耳机线控）

---

## 十二、参考资料

| 主题 | 官方文档 |
|------|---------|
| CoreSpeechKit TTS 开发 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-kit-guide |
| AVSession 媒体会话提供方 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/using-avsession-developer-V5 |
| BackgroundTasks 长时任务 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V14/continuous-task-V14 |
| AudioRenderer 音频播放 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/audio-renderer |
| Canvas 动画开发 | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-canvasrenderingcontext2d |
| 应用开发总指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide |
