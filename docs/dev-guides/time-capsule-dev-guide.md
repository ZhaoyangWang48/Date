# 时光胶囊 · Time Capsule — 开发指导文档

> **适用平台**：HarmonyOS NEXT (API 14+, HarmonyOS 5.0.2)  
> **目标项目**：植忆 (com.example.date)  
> **文档用途**：指导 AI 按照官方规范完成功能开发

---

## 一、功能概述

### 1.1 产品定义

写一段记忆，设定一个未来的"开启日期"，把它封入时光胶囊。到达日期之前，这段记忆在记忆树上是一个"埋在土里的金色花苞"；到达那天，花苞破土而出，长成一片会发光的金色记忆叶。用户收到通知，打开花苞，TTS 自动朗读当年写给自己的话。

### 1.2 核心玩法

| 动作 | 描述 |
|------|------|
| **封存** | 写内容 + 选心情 + 选开启日期（1周/1月/3月/1年/自定义），确认后"埋入地下" |
| **等待** | 记忆树上，未开启的胶囊以**金色闭合花苞**形态悬挂在树枝上，点击显示倒计时 |
| **开启** | 到期日通知栏提醒 → 进入 App → 花苞绽放动画 → 金色发光叶 → TTS 自动朗读 |
| **回顾** | 已开启的胶囊显示在"胶囊花园"，按时间轴排列，可朗读、可查看 |
| **胶囊花园** | 独立页面，像考古地层一样按时间排列所有胶囊（已开启 + 等待中） |

### 1.3 鸿蒙能力运用

| 能力 | 用途 | 对应 Kit/API |
|------|------|-------------|
| **通知服务** | 到期当天推送提醒 | `@kit.NotificationKit` |
| **WantAgent** | 点击通知直接跳转开启胶囊页面 | `@kit.AbilityKit` |
| **日历提醒** | 将开启日期写入系统日历，双通道保障 | `@kit.CalendarKit` |
| **TTS 语音朗读** | 开启后自动朗读"过去的自己写给现在的信" | `@kit.CoreSpeechKit` |
| **Canvas 动画** | 花苞绽放贝塞尔动画 + 金色光粒子 | `@kit.ArkUI` Canvas |
| **AppStorage** | EntryAbility 接收通知参数并路由 | `@kit.ArkUI` |

---

## 二、架构设计

### 2.1 新增文件清单

```
entry/src/main/ets/
├── models/
│   └── TimeCapsule.ets               ← 胶囊数据模型
├── repositories/
│   └── TimeCapsuleRepository.ets     ← 胶囊 API 仓库层
├── viewmodels/
│   ├── TimeCapsuleViewModel.ets      ← 胶囊业务编排
│   └── TimeCapsuleBloomEngine.ets    ← 花苞绽放动画引擎（贝塞尔花瓣展开 + 粒子特效）
├── services/
│   ├── CapsuleReminderService.ets    ← 到期提醒服务（通知 + 日历双通道）
│   └── CapsuleTtsService.ets         ← 胶囊朗读服务（复用 TtsService 单例）
├── components/
│   ├── CapsuleBud.ets                ← 记忆树上的花苞组件
│   ├── TimeCapsuleCard.ets           ← 胶囊花园中的胶囊卡片
│   └── CapsuleBloomCanvas.ets        ← 花苞绽放 Canvas 动画组件
└── pages/
    ├── TimeCapsuleGardenPage.ets     ← 胶囊花园主页面
    └── CapsuleOpenPage.ets           ← 开启胶囊仪式感页面（全屏动画 + TTS 朗读）
```

### 2.2 修改文件清单

```
entry/src/main/ets/
├── constants/AppRoutes.ets           ← 新增 TIME_CAPSULE_GARDEN 路由
├── pages/MainTabPage.ets             ← 可选：底部导航增加胶囊入口
├── viewmodels/TreeGrowthEngine.ets   ← 可选：新增 capsuleLeaves 到快照
├── components/VineTreeCanvas.ets     ← 可选：绘制花苞形态的胶囊节点
├── entryability/EntryAbility.ets     ← 增加 onNewWant 通知路由处理
└── entry/src/main/module.json5       ← 新增通知权限 + 日历权限
```

---

## 三、数据模型

### 3.1 TimeCapsule.ets

```typescript
// models/TimeCapsule.ets

/**
 * 时光胶囊数据模型
 *
 * 一段被封存到未来某一天才可开启的记忆。
 */
export class TimeCapsule {
  /** 胶囊唯一 ID */
  id: number = 0;

  /** 作者 ID */
  authorId: number = 0;

  /** 作者昵称（开启后可见） */
  authorName: string = '';

  /** 记忆文字内容 */
  content: string = '';

  /** 心情标签：calm/happy/excited/sad/tired */
  mood: string = 'calm';

  /** 封存日期（ISO 8601） */
  sealDate: string = '';

  /** 计划开启日期（ISO 8601） */
  openDate: string = '';

  /** 实际开启日期（ISO 8601），未开启时为空 */
  actualOpenDate: string = '';

  /** 是否已开启 */
  isOpened: boolean = false;

  constructor(
    id: number = 0, authorId: number = 0, authorName: string = '',
    content: string = '', mood: string = 'calm',
    sealDate: string = '', openDate: string = '', isOpened: boolean = false
  ) {
    this.id = id;
    this.authorId = authorId;
    this.authorName = authorName;
    this.content = content;
    this.mood = mood;
    this.sealDate = sealDate;
    this.openDate = openDate;
    this.isOpened = isOpened;
  }

  /** 计算剩余天数（负数表示已过期未开启） */
  remainingDays(): number {
    if (this.isOpened) return 0;
    if (!this.openDate) return 0;
    const target = new Date(this.openDate).getTime();
    const now = Date.now();
    return Math.ceil((target - now) / 86400000);
  }

  /** 是否已到达开启日期 */
  isReady(): boolean {
    return !this.isOpened && this.remainingDays() <= 0;
  }

  /** 剩余天数的可读文本 */
  remainingText(): string {
    if (this.isOpened) return '已开启';
    const days = this.remainingDays();
    if (days <= 0) return '今天可以开启了！';
    if (days === 1) return '明天开启';
    if (days < 30) return `还有 ${days} 天`;
    if (days < 365) return `还有 ${Math.floor(days / 30)} 个月`;
    return `还有 ${Math.floor(days / 365)} 年`;
  }
}

/**
 * 预设的开启时间选项
 */
export class CapsuleTimeOptions {
  static readonly OPTIONS = [
    { label: '1 周后', days: 7 },
    { label: '1 个月后', days: 30 },
    { label: '3 个月后', days: 90 },
    { label: '1 年后', days: 365 },
    { label: '自定义', days: -1 }
  ];

  /** 根据天数索引计算开启日期 */
  static openDateFromDays(days: number): string {
    const now = new Date();
    now.setDate(now.getDate() + days);
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  }
}
```

### 3.2 API 请求体追加

```typescript
// 在 models/ApiRequests.ets 中追加
export class CreateTimeCapsuleRequestBody {
  content: string = '';
  mood: string = 'calm';
  openDate: string = '';

  constructor(content: string, mood: string, openDate: string) {
    this.content = content;
    this.mood = mood;
    this.openDate = openDate;
  }
}
```

---

## 四、动画引擎

### 4.1 TimeCapsuleBloomEngine.ets — 花苞绽放动画引擎

```typescript
// viewmodels/TimeCapsuleBloomEngine.ets

/**
 * 单帧花苞绽放状态
 */
export class BloomFrame {
  /** 5 片花瓣的展开角度（0=闭合花苞, 1=完全展开） */
  petalAngles: number[] = [];

  /** 花心缩放比例 */
  centerScale: number = 1;

  /** 光晕透明度（0~1） */
  glowAlpha: number = 0;

  /** 飘散粒子的位置和透明度 */
  sparkles: { x: number; y: number; alpha: number; size: number }[] = [];

  constructor() {
    this.petalAngles = new Array(5).fill(0);
  }
}

/**
 * 花苞绽放动画引擎
 *
 * 生成 48 帧的绽放动画序列（约 2 秒，24 FPS）。
 * 动画分三个阶段：
 *   0%~30%: 花苞微微颤动（蓄力）
 *  30%~70%: 花瓣依次展开（核心绽放）
 *  70%~100%: 粒子光点爆发 + 光晕渐亮（庆祝）
 *
 * 动画方式：使用 setInterval 驱动。
 * 官方说明：HarmonyOS NEXT 中 Canvas 组件不完全支持 requestAnimationFrame，
 * 推荐使用 setInterval 作为替代方案。
 * 参考：HarmonyOS NEXT Canvas 动画开发实践
 */
export class TimeCapsuleBloomEngine {
  static readonly PETAL_COUNT: number = 5;
  static readonly TOTAL_FRAMES: number = 48;       // 总帧数
  static readonly FRAME_INTERVAL: number = 42;      // 帧间隔 ms（≈24 FPS）
  static readonly TOTAL_DURATION: number = 2000;    // 总时长 ms

  /**
   * 生成全部 48 帧的绽放动画序列
   *
   * @returns BloomFrame[] 动画帧数组
   */
  static generateFrames(): BloomFrame[] {
    const frames: BloomFrame[] = [];

    for (let frame = 0; frame < TimeCapsuleBloomEngine.TOTAL_FRAMES; frame++) {
      const t = frame / TimeCapsuleBloomEngine.TOTAL_FRAMES;  // 归一化时间 [0, 1]

      // ease-in-out 缓动函数：先慢后快再慢
      const eased = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

      const f = new BloomFrame();

      // ---- 阶段 1：花苞颤动（0% ~ 30%） ----
      // 阶段 2：花瓣展开（30% ~ 70%） ----
      // 阶段 3：光晕 + 粒子（70% ~ 100%） ----

      // 花瓣展开：5 片花瓣依次延迟 0.06t 展开
      for (let petal = 0; petal < TimeCapsuleBloomEngine.PETAL_COUNT; petal++) {
        const petalStart = petal * 0.06;                     // 相邻花瓣延迟 6%
        const petalDuration = 0.55;                           // 每片花瓣展开耗时
        const petalT = Math.max(0, Math.min(1, (eased - petalStart) / petalDuration));
        // 花瓣最大展开角度约 72° = 0.4π rad（不完全水平，保留弧度）
        f.petalAngles[petal] = petalT * Math.PI * 0.4;
      }

      // 花心缩放：在绽放中期微微放大，后期缩回
      f.centerScale = 1.0 + Math.sin(eased * Math.PI) * 0.12;

      // 光晕：花瓣展开 60% 后开始出现
      const glowStart = 0.6;
      f.glowAlpha = Math.max(0, Math.min(1, (eased - glowStart) / (1 - glowStart))) * 0.65;

      // 粒子光点：80% 后爆发
      if (t > 0.8) {
        const particleCount = Math.floor((t - 0.8) / 0.2 * 22);
        for (let p = 0; p < particleCount; p++) {
          const angle = (p / particleCount) * Math.PI * 2 + (frame * 0.11);  // 旋转
          const distance = 28 + (t - 0.8) / 0.2 * 85;                        // 扩散距离
          f.sparkles.push({
            x: Math.cos(angle) * distance,
            y: Math.sin(angle) * distance - 8,
            alpha: 0.3 + Math.random() * 0.7,
            size: 0.8 + Math.random() * 2.2
          });
        }
      }

      frames.push(f);
    }

    return frames;
  }

  /**
   * 为记忆树上的花苞渲染生成"待开启"状态的静态帧
   *
   * 花苞闭合，偶尔有微小的光点闪烁
   *
   * @param seed 确定性种子（如 userId），确保同一用户的花苞看起来一致
   * @returns 闭合状态的 BloomFrame
   */
  static sealedFrame(seed: number): BloomFrame {
    const f = new BloomFrame();

    // 所有花瓣闭合
    for (let p = 0; p < TimeCapsuleBloomEngine.PETAL_COUNT; p++) {
      f.petalAngles[p] = 0.05;  // 微张 5%，看起来像一个花苞而非一个球
    }

    f.centerScale = 1.0;
    f.glowAlpha = 0.12;  // 微弱光晕，表示"活的"

    // 1~3 个微小光点围绕花苞旋转
    const sparkleCount = 1 + (seed % 3);
    const state = seed;
    for (let s = 0; s < sparkleCount; s++) {
      const angle = ((state + s * 137) % 360) * Math.PI / 180;
      f.sparkles.push({
        x: Math.cos(angle) * 22,
        y: Math.sin(angle) * 18,
        alpha: 0.15 + (s * 0.1),
        size: 0.6 + s * 0.3
      });
    }

    return f;
  }
}
```

---

## 五、服务层

### 5.1 CapsuleReminderService.ets — 到期提醒（通知 + 日历双通道）

```typescript
// services/CapsuleReminderService.ets

import { notificationManager } from '@kit.NotificationKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { calendarManager } from '@kit.CalendarKit';
import { Context } from '@kit.AbilityKit';
import { AppRoutes } from '../constants/AppRoutes';

/**
 * 胶囊到期提醒服务
 *
 * 双通道保障用户不会错过开启日：
 *   通道 1 — 通知栏提醒：到期当天上午 9:00 推送
 *   通道 2 — 系统日历日程：创建日历提醒，用户可在日历 App 中看到
 *
 * 官方参考：
 *   - Notification Kit: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-overview
 *   - Calendar Kit: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/calendar-kit-overview
 *   - WantAgent: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wantagent-overview
 */
export class CapsuleReminderService {
  private static readonly NOTIFICATION_ID_BASE: number = 3000;  // 胶囊通知 ID 基数

  /**
   * 为胶囊设置到期提醒
   *
   * @param context   应用上下文
   * @param capsuleId 胶囊 ID
   * @param openDate  开启日期（格式: "YYYY-MM-DD"）
   * @param content   记忆内容摘要（用于提醒文案）
   */
  static async scheduleReminder(
    context: Context, capsuleId: number, openDate: string, content: string
  ): Promise<void> {
    const openTime = new Date(openDate + 'T09:00:00').getTime();  // 当天上午 9 点

    // 如果到期时间已过，直接发送即时通知
    if (openTime <= Date.now()) {
      await CapsuleReminderService.sendImmediateNotification(context, capsuleId, content);
      return;
    }

    // ---- 通道 1：定时通知 ----
    await CapsuleReminderService.scheduleNotification(context, capsuleId, openTime, content);

    // ---- 通道 2：系统日历日程 ----
    await CapsuleReminderService.addCalendarEvent(context, capsuleId, openDate, content);
  }

  /**
   * 通道 1：定时通知
   *
   * 使用 notificationManager 的 deliveryTime 参数定时触发
   */
  private static async scheduleNotification(
    context: Context, capsuleId: number, triggerTime: number, content: string
  ): Promise<void> {
    const agent = await CapsuleReminderService.createCapsuleWantAgent(context, capsuleId);

    const snippet = content.length > 30 ? content.substring(0, 30) + '…' : content;

    const request: notificationManager.NotificationRequest = {
      id: CapsuleReminderService.NOTIFICATION_ID_BASE + capsuleId,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '⏳ 时光胶囊已就绪',
          text: `"${snippet}"`,
          additionalText: '点击开启你的时光胶囊'
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      deliveryTime: triggerTime,   // ⭐ 定时触发时间戳（ms）
      wantAgent: agent,
      isOngoing: false
    };

    try {
      await notificationManager.publish(request);
      console.info(`[Capsule] 定时通知已设置 capsuleId=${capsuleId} triggerTime=${triggerTime}`);
    } catch (err) {
      console.error(`[Capsule] 定时通知设置失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 通道 2：写入系统日历
   *
   * Calendar Kit 官方文档要求：
   * - 权限: ohos.permission.READ_CALENDAR + ohos.permission.WRITE_CALENDAR
   * - 时间戳格式: 13 位毫秒级
   */
  private static async addCalendarEvent(
    context: Context, capsuleId: number, openDate: string, content: string
  ): Promise<void> {
    try {
      const calMgr = calendarManager.getCalendarManager(context);
      const calendar = await calMgr.getCalendar();

      const openTimeMs = new Date(openDate + 'T09:00:00').getTime();
      const snippet = content.length > 50 ? content.substring(0, 50) + '…' : content;

      const event: calendarManager.Event = {
        type: calendarManager.EventType.NORMAL,
        title: `🌱 时光胶囊开启：「${snippet}」`,
        description: `你在植忆中封存了一段记忆，今天是开启的日子。\n\n内容预览：${content}`,
        startTime: openTimeMs,
        endTime: openTimeMs + 3600000,  // 持续时间 1 小时
        reminderTime: [0, 30],          // 准时 + 提前 30 分钟各提醒一次
        timeZone: 'Asia/Shanghai'
      };

      const eventId = await calendar.addEvent(event);
      console.info(`[Capsule] 日历日程已创建 capsuleId=${capsuleId} eventId=${eventId}`);
    } catch (err) {
      console.warn(`[Capsule] 日历日程创建失败（非致命，通知通道已保障）: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 即时通知（到期时间已过时使用）
   */
  private static async sendImmediateNotification(
    context: Context, capsuleId: number, content: string
  ): Promise<void> {
    const agent = await CapsuleReminderService.createCapsuleWantAgent(context, capsuleId);
    const snippet = content.length > 30 ? content.substring(0, 30) + '…' : content;

    const request: notificationManager.NotificationRequest = {
      id: CapsuleReminderService.NOTIFICATION_ID_BASE + capsuleId,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '⏳ 时光胶囊已就绪',
          text: `"${snippet}"`,
          additionalText: '点击开启你的时光胶囊'
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      wantAgent: agent,
      isOngoing: false
    };

    await notificationManager.publish(request);
  }

  /**
   * 创建跳转胶囊开启页的 WantAgent
   */
  private static async createCapsuleWantAgent(
    context: Context, capsuleId: number
  ): Promise<WantAgent> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: 'com.example.date',
        abilityName: 'EntryAbility',
        parameters: {
          targetRoute: 'capsule_open',    // 目标路由标识
          capsuleId: String(capsuleId)    // 胶囊 ID
        }
      }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: CapsuleReminderService.NOTIFICATION_ID_BASE + capsuleId,
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    };

    return await wantAgent.getWantAgent(wantAgentInfo);
  }
}
```

### 5.2 CapsuleTtsService.ets — 胶囊朗读服务（复用 TtsService）

```typescript
// services/CapsuleTtsService.ets

/**
 * 时光胶囊朗读服务
 *
 * 封装时光胶囊场景的 TTS 朗读逻辑，使用项目已有的 TtsService 单例。
 *
 * 不单独创建 TTS 引擎，直接复用 TtsService（参见 drift-bottle 方案中的 TtsService）。
 * 这里的代码是独立的业务包装层，负责构建朗读文本。
 */
export class CapsuleTtsService {
  /**
   * 构建胶囊开启时的朗读文本
   *
   * 使用 [pN] 内联标记控制停顿节奏：
   *   - 日期和昵称之间停顿 400ms
   *   - 封存日期和内容之间停顿 600ms
   *   - 营造娓娓道来的仪式感
   *
   * 内联标记语法参考：
   *   [pN] = 插入 N 毫秒静音停顿
   *   官方文档: CoreSpeechKit textToSpeech 支持的文本标记
   *
   * @param sealDate   封存日期
   * @param openDate   开启日期
   * @param authorName 作者昵称
   * @param content    记忆内容
   * @param mood       心情标签
   * @returns 格式化后的朗读文本
   */
  static buildOpenScript(
    sealDate: string, openDate: string, authorName: string, content: string, mood: string
  ): string {
    // 计算过去了多久
    const elapsedDays = Math.floor(
      (new Date(openDate).getTime() - new Date(sealDate).getTime()) / 86400000
    );
    const elapsedText = elapsedDays <= 30
      ? `${elapsedDays}天前`
      : elapsedDays <= 365
        ? `${Math.floor(elapsedDays / 30)}个月前`
        : `${Math.floor(elapsedDays / 365)}年前`;

    const moodLabels: Record<string, string> = {
      'calm': '平静', 'happy': '开心', 'excited': '雀跃', 'sad': '低落', 'tired': '疲惫'
    };
    const moodLabel = moodLabels[mood] ?? '平静';

    // 构建朗读脚本
    return [
      `${elapsedText}[p500]，${authorName}[p300]封存了一段时光胶囊。`,
      `[p800]当时的心情是${moodLabel}。`,
      `[p600]${content.replace(/[\u{1F600}-\u{1F6FF}★☆✦◌☀☂☾]/gu, '')}`,
      `[p1200]以上是来自过去的信。[p400]你可以把它留在花园里，随时回来听。`
    ].join('');
  }
}
```

---

## 六、仓库层

### 6.1 TimeCapsuleRepository.ets

```typescript
// repositories/TimeCapsuleRepository.ets

import { TimeCapsule } from '../models/TimeCapsule';
import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { CreateTimeCapsuleRequestBody } from '../models/ApiRequests';

/**
 * 时光胶囊仓库层
 *
 * API 端点（需后端配合）：
 * - POST   /api/time-capsules         → 创建胶囊
 * - GET    /api/time-capsules          → 获取我的所有胶囊
 * - GET    /api/time-capsules/:id      → 获取单个胶囊
 * - PATCH  /api/time-capsules/:id/open → 标记胶囊已开启
 */
export class TimeCapsuleRepository {
  private readonly http: HttpClient = new HttpClient();

  private static readonly CAPSULES: string = '/api/time-capsules';

  /**
   * 创建时光胶囊
   */
  async create(
    context: Context, content: string, mood: string, openDate: string
  ): Promise<ApiResult<TimeCapsule>> {
    const token = await TokenStorage.getToken(context);
    const body = new CreateTimeCapsuleRequestBody(content, mood, openDate);
    return this.toCapsule(
      await this.http.post<TimeCapsule>(TimeCapsuleRepository.CAPSULES, body, token)
    );
  }

  /**
   * 获取我的所有胶囊（未开启 + 已开启）
   */
  async listMine(context: Context): Promise<ApiResult<TimeCapsule[]>> {
    const token = await TokenStorage.getToken(context);
    return this.toCapsules(
      await this.http.get<TimeCapsule[]>(TimeCapsuleRepository.CAPSULES, token)
    );
  }

  /**
   * 获取单个胶囊详情
   */
  async getById(context: Context, capsuleId: number): Promise<ApiResult<TimeCapsule>> {
    const token = await TokenStorage.getToken(context);
    return this.toCapsule(
      await this.http.get<TimeCapsule>(
        `${TimeCapsuleRepository.CAPSULES}/${capsuleId}`, token
      )
    );
  }

  /**
   * 标记胶囊已开启
   */
  async markOpened(context: Context, capsuleId: number): Promise<ApiResult<TimeCapsule>> {
    const token = await TokenStorage.getToken(context);
    return this.toCapsule(
      await this.http.patch<TimeCapsule>(
        `${TimeCapsuleRepository.CAPSULES}/${capsuleId}/open`, {}, token
      )
    );
  }

  // ----- 数据规范化 -----
  private toCapsule(result: ApiResult<TimeCapsule>): ApiResult<TimeCapsule> {
    if (result.data === undefined) return result;
    const c = result.data;
    return new ApiResult<TimeCapsule>(result.code, result.message,
      new TimeCapsule(c.id, c.authorId, c.authorName, c.content, c.mood,
        c.sealDate, c.openDate, c.isOpened));
  }

  private toCapsules(result: ApiResult<TimeCapsule[]>): ApiResult<TimeCapsule[]> {
    if (result.data === undefined) return result;
    return new ApiResult<TimeCapsule[]>(result.code, result.message,
      result.data.map(c => new TimeCapsule(c.id, c.authorId, c.authorName,
        c.content, c.mood, c.sealDate, c.openDate, c.isOpened)));
  }
}
```

---

## 七、ViewModel 层

### 7.1 TimeCapsuleViewModel.ets

```typescript
// viewmodels/TimeCapsuleViewModel.ets

import { TimeCapsule } from '../models/TimeCapsule';
import { TimeCapsuleRepository } from '../repositories/TimeCapsuleRepository';
import { CapsuleReminderService } from '../services/CapsuleReminderService';
import { Context } from '@kit.AbilityKit';

export class CapsuleActionResult {
  success: boolean = false;
  message: string = '';
  capsule: TimeCapsule | undefined = undefined;

  constructor(success: boolean, message: string, capsule?: TimeCapsule) {
    this.success = success;
    this.message = message;
    this.capsule = capsule;
  }
}

export class TimeCapsuleViewModel {
  private readonly repository: TimeCapsuleRepository = new TimeCapsuleRepository();

  /**
   * 封存时光胶囊
   *
   * @param context  应用上下文
   * @param content  记忆内容
   * @param mood     心情标签
   * @param openDate 开启日期（YYYY-MM-DD）
   */
  async seal(
    context: Context, content: string, mood: string, openDate: string
  ): Promise<CapsuleActionResult> {
    const text = content.trim();
    if (text.length === 0) {
      return new CapsuleActionResult(false, '请写下一段想对未来的自己说的话');
    }
    if (text.length > 10000) {
      return new CapsuleActionResult(false, '内容不能超过 10000 字');  // TTS 单次上限
    }
    if (!openDate || openDate.length === 0) {
      return new CapsuleActionResult(false, '请选择一个开启日期');
    }

    const openTime = new Date(openDate + 'T23:59:59').getTime();
    if (openTime <= Date.now()) {
      return new CapsuleActionResult(false, '开启日期必须在未来，请重新选择');
    }

    // 创建胶囊
    const result = await this.repository.create(context, text, mood, openDate);
    if (result.code !== 200 || result.data === undefined) {
      return new CapsuleActionResult(false, result.message || '胶囊封存失败，请重试');
    }

    const capsule = result.data;

    // 设置到期提醒（通知 + 日历双通道）
    try {
      await CapsuleReminderService.scheduleReminder(context, capsule.id, openDate, text);
    } catch (err) {
      console.warn(`[Capsule] 提醒设置失败（非致命）: ${JSON.stringify(err)}`);
    }

    return new CapsuleActionResult(true, '💛 时光胶囊已埋入地下', capsule);
  }

  /**
   * 开启胶囊
   *
   * 标记 isOpened=true，返回胶囊供 TTS 朗读
   */
  async open(context: Context, capsuleId: number): Promise<CapsuleActionResult> {
    const result = await this.repository.markOpened(context, capsuleId);
    if (result.code !== 200 || result.data === undefined) {
      return new CapsuleActionResult(false, result.message || '胶囊开启失败');
    }
    return new CapsuleActionResult(true, '时光胶囊已开启 ✨', result.data);
  }

  /** 获取所有胶囊 */
  async listCapsules(context: Context): Promise<TimeCapsule[]> {
    const result = await this.repository.listMine(context);
    if (result.data === undefined) return [];
    // 排序：未开启的按到期日升序，已开启的按封存日降序
    return result.data.sort((a: TimeCapsule, b: TimeCapsule) => {
      if (a.isOpened !== b.isOpened) return a.isOpened ? 1 : -1;
      if (!a.isOpened) return new Date(a.openDate).getTime() - new Date(b.openDate).getTime();
      return new Date(b.sealDate).getTime() - new Date(a.sealDate).getTime();
    });
  }

  /** 获取单个胶囊 */
  async getCapsule(context: Context, capsuleId: number): Promise<TimeCapsule | undefined> {
    const result = await this.repository.getById(context, capsuleId);
    return result.data;
  }
}
```

---

## 八、Canvas 动画组件

### 8.1 CapsuleBloomCanvas.ets — 花苞绽放动画

```typescript
// components/CapsuleBloomCanvas.ets

import { TimeCapsuleBloomEngine, BloomFrame } from '../viewmodels/TimeCapsuleBloomEngine';
import { MoodTypes } from '../constants/MoodTypes';

/**
 * 花苞绽放 Canvas 动画组件
 *
 * 在 CapsuleOpenPage 中使用，展示花苞从闭合到完全绽放的全过程。
 *
 * 参考：
 *   - CanvasRenderingContext2D 文档
 *   - 植忆已有的 VineTreeCanvas.ets 实现
 *
 * 性能：
 *   - RenderingContextSettings(true) 启用抗锯齿
 *   - 贝塞尔曲线使用少量控制点
 *   - 粒子数量控制在 20 以内
 */
@Component
export struct CapsuleBloomCanvas {
  @Prop capsuleMood: string = 'calm';
  @Prop isAnimating: boolean = false;
  @Prop currentFrame: number = 0;
  onAnimationComplete: () => void = () => {};

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private frames: BloomFrame[] = [];
  private readonly WIDTH: number = 300;
  private readonly HEIGHT: number = 320;
  private readonly CENTER_X: number = 150;
  private readonly CENTER_Y: number = 170;

  aboutToAppear(): void {
    this.frames = TimeCapsuleBloomEngine.generateFrames();
  }

  build() {
    Canvas(this.ctx)
      .width(this.WIDTH)
      .height(this.HEIGHT)
      .borderRadius(20)
  }

  /**
   * 外部调用：绘制指定帧
   */
  drawFrame(frameIndex: number): void {
    if (frameIndex >= this.frames.length) return;
    const frame = this.frames[frameIndex];
    this.ctx.clearRect(0, 0, this.WIDTH, this.HEIGHT);
    this.drawBackground();
    this.drawStem();
    this.drawPetals(frame);
    this.drawCenter(frame);
    this.drawGlow(frame);
    this.drawSparkles(frame);
  }

  /** 绘制已闭合的花苞（静态，用于列表展示） */
  drawSealed(): void {
    const frame = TimeCapsuleBloomEngine.sealedFrame(Date.now());
    this.ctx.clearRect(0, 0, this.WIDTH, this.HEIGHT);
    this.drawBackground();
    this.drawStem();
    this.drawPetals(frame);
    this.drawCenter(frame);
    this.drawGlow(frame);
    this.drawSparkles(frame);
  }

  // ── 以下为绘制子步骤 ──

  private drawBackground(): void {
    const grad = this.ctx.createRadialGradient(
      this.CENTER_X, this.CENTER_Y, 20,
      this.CENTER_X, this.CENTER_Y, 200
    );
    grad.addColorStop(0, '#FDFCF7');
    grad.addColorStop(0.6, '#F2F0E8');
    grad.addColorStop(1, '#E8E4D8');
    this.ctx.fillStyle = grad;
    this.ctx.fillRect(0, 0, this.WIDTH, this.HEIGHT);
  }

  private drawStem(): void {
    this.ctx.save();
    this.ctx.strokeStyle = '#5B8C6F';
    this.ctx.lineWidth = 2.8;
    this.ctx.lineCap = 'round';
    this.ctx.beginPath();
    this.ctx.moveTo(this.CENTER_X, this.CENTER_Y + 18);
    this.ctx.quadraticCurveTo(
      this.CENTER_X + 4, this.CENTER_Y + 55,
      this.CENTER_X - 2, this.HEIGHT - 10
    );
    this.ctx.stroke();
    this.ctx.restore();
  }

  private drawPetals(frame: BloomFrame): void {
    const moodColor = this.moodHex();
    for (let p = 0; p < TimeCapsuleBloomEngine.PETAL_COUNT; p++) {
      const baseAngle = (p / TimeCapsuleBloomEngine.PETAL_COUNT) * Math.PI * 2 - Math.PI / 2;
      const openAngle = frame.petalAngles[p];

      this.ctx.save();
      this.ctx.translate(this.CENTER_X, this.CENTER_Y);
      this.ctx.rotate(baseAngle);

      const petalLen = 42;
      const tipX = 0 + Math.sin(openAngle) * petalLen;
      const tipY = -18 - Math.cos(openAngle) * petalLen;

      // 花瓣形状：贝塞尔曲线
      const gradient = this.ctx.createLinearGradient(0, -6, tipX, tipY);
      gradient.addColorStop(0, '#FFF8E7');
      gradient.addColorStop(0.35, moodColor);
      gradient.addColorStop(1, '#C8963E');
      this.ctx.fillStyle = gradient;

      this.ctx.beginPath();
      this.ctx.moveTo(0, -4);
      this.ctx.bezierCurveTo(8, tipY * 0.2, tipX * 0.5 + 6, tipY * 0.5, tipX, tipY);
      this.ctx.bezierCurveTo(tipX * 0.5 - 6, tipY * 0.5, -8, tipY * 0.2, 0, -4);
      this.ctx.fill();

      this.ctx.restore();
    }
  }

  private drawCenter(frame: BloomFrame): void {
    this.ctx.save();
    this.ctx.translate(this.CENTER_X, this.CENTER_Y);
    this.ctx.scale(frame.centerScale, frame.centerScale);

    // 花心
    const centerGrad = this.ctx.createRadialGradient(0, 0, 1, 0, 0, 10);
    centerGrad.addColorStop(0, '#FFF3CD');
    centerGrad.addColorStop(1, '#D4A84B');
    this.ctx.fillStyle = centerGrad;
    this.ctx.beginPath();
    this.ctx.arc(0, 0, 9, 0, Math.PI * 2);
    this.ctx.fill();

    this.ctx.restore();
  }

  private drawGlow(frame: BloomFrame): void {
    if (frame.glowAlpha <= 0) return;
    this.ctx.save();
    this.ctx.globalAlpha = frame.glowAlpha;
    const glowGrad = this.ctx.createRadialGradient(
      this.CENTER_X, this.CENTER_Y, 10,
      this.CENTER_X, this.CENTER_Y, 80
    );
    glowGrad.addColorStop(0, '#FFE9A0');
    glowGrad.addColorStop(0.5, '#FFD66630');
    glowGrad.addColorStop(1, '#FFD66600');
    this.ctx.fillStyle = glowGrad;
    this.ctx.beginPath();
    this.ctx.arc(this.CENTER_X, this.CENTER_Y, 80, 0, Math.PI * 2);
    this.ctx.fill();
    this.ctx.restore();
  }

  private drawSparkles(frame: BloomFrame): void {
    for (const sparkle of frame.sparkles) {
      this.ctx.save();
      this.ctx.globalAlpha = sparkle.alpha;
      this.ctx.fillStyle = '#FFE9A0';
      this.ctx.beginPath();
      this.ctx.arc(
        this.CENTER_X + sparkle.x,
        this.CENTER_Y + sparkle.y,
        sparkle.size,
        0, Math.PI * 2
      );
      this.ctx.fill();
      this.ctx.restore();
    }
  }

  private moodHex(): string {
    switch (this.capsuleMood) {
      case 'happy': return '#E2A94B';
      case 'excited': return '#D97979';
      case 'sad': return '#7D9DA6';
      case 'tired': return '#8E87A2';
      default: return '#CDA560';  // calm → 金色（胶囊主题色）
    }
  }
}
```

---

## 九、页面

### 9.1 TimeCapsuleGardenPage.ets — 胶囊花园

```typescript
// pages/TimeCapsuleGardenPage.ets

import { TimeCapsule, CapsuleTimeOptions } from '../models/TimeCapsule';
import { TimeCapsuleViewModel } from '../viewmodels/TimeCapsuleViewModel';
import { StatePanel } from '../components/StatePanel';
import { MoodTypes } from '../constants/MoodTypes';
import { CapsuleTtsService } from '../services/CapsuleTtsService';
import { TtsService, TtsState } from '../services/TtsService';

/**
 * 胶囊花园页面
 *
 * 以时间轴形式排列所有胶囊（未开启在上，已开启在下）。
 */
@Entry
@Component
struct TimeCapsuleGardenPage {
  @State capsules: TimeCapsule[] = [];
  @State loading: boolean = false;
  @State errorMessage: string = '';
  @State message: string = '';
  @State showSealForm: boolean = false;

  // 封存表单
  @State sealContent: string = '';
  @State sealMood: string = 'calm';
  @State sealOpenDays: number = 30;
  @State sealCustomDate: string = '';

  // TTS
  @State ttsState: TtsState = TtsState.IDLE;
  private readonly viewModel: TimeCapsuleViewModel = new TimeCapsuleViewModel();
  private readonly tts: TtsService = TtsService.getInstance();

  aboutToAppear(): void {
    this.initialize();
  }

  private async initialize(): Promise<void> {
    this.loading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.capsules = await this.viewModel.listCapsules(context);
    } catch (err) {
      this.errorMessage = '胶囊花园加载失败';
    }
    this.loading = false;
  }

  private async sealCapsule(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;

    const openDate = this.sealOpenDays === -1
      ? this.sealCustomDate
      : CapsuleTimeOptions.openDateFromDays(this.sealOpenDays);

    const result = await this.viewModel.seal(context, this.sealContent, this.sealMood, openDate);
    if (result.success) {
      this.message = result.message;
      this.sealContent = '';
      this.showSealForm = false;
      this.capsules = await this.viewModel.listCapsules(context);
    } else {
      this.message = result.message;
    }
  }

  private readCapsule(capsule: TimeCapsule): void {
    const script = CapsuleTtsService.buildOpenScript(
      capsule.sealDate, capsule.openDate, capsule.authorName, capsule.content, capsule.mood
    );
    this.tts.speak(script);
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  build() {
    Scroll() {
      Column({ space: 0 }) {
        // 顶部
        Row({ space: 10 }) {
          Text('‹')
            .fontSize(34).fontWeight(FontWeight.Lighter)
            .fontColor($r('app.color.primary'))
            .onClick(() => { this.goBack(); })
          Text('⏳ 胶囊花园')
            .fontSize(24).fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
        }
        .width('100%')

        Text('每一颗胶囊，都是你寄给未来的一封信')
          .fontSize(14).fontColor($r('app.color.text_secondary'))
          .margin({ top: 8, bottom: 20 }).width('100%')

        Button('+ 封存新胶囊')
          .width('100%').height(48)
          .fontSize(15).fontColor($r('app.color.on_primary'))
          .backgroundColor($r('app.color.primary'))
          .borderRadius(14)
          .onClick(() => { this.showSealForm = !this.showSealForm; })

        // 封存表单
        if (this.showSealForm) {
          this.buildSealForm()
        }

        if (this.message.length > 0) {
          Text(this.message).fontSize(13)
            .fontColor($r('app.color.primary')).width('100%').margin({ top: 12 })
        }

        if (this.loading) {
          StatePanel({ title: '正在整理花园', description: '胶囊们正在归位。', stateIcon: '⏳' })
        } else if (this.errorMessage.length > 0) {
          StatePanel({ title: '加载失败', description: this.errorMessage, stateIcon: '!' })
        } else if (this.capsules.length === 0) {
          StatePanel({ title: '花园还是空的', description: '封存你的第一个时光胶囊，寄给未来的自己。', stateIcon: '🌱' })
        } else {
          // 等待中的胶囊
          this.buildCapsuleSection('等待开启', true)
          // 已开启的胶囊
          this.buildCapsuleSection('已开启', false)
        }
      }
      .alignItems(HorizontalAlign.Start).width('100%')
      .padding({ left: 20, right: 20, top: 38, bottom: 28 })
    }
    .width('100%').height('100%').scrollBar(BarState.Off)
    .backgroundColor($r('app.color.app_background'))
  }

  @Builder
  private buildSealForm(): void {
    Column({ space: 12 }) {
      TextArea({ placeholder: '写给未来自己的一段话…', text: this.sealContent })
        .height(120).padding(14).fontSize(15)
        .backgroundColor($r('app.color.surface')).borderRadius(14)
        .border({ width: 1, color: $r('app.color.outline') })
        .onChange((v: string) => { this.sealContent = v; })

      // 心情选择
      Row({ space: 8 }) {
        ForEach(MoodTypes.OPTIONS, (opt: MoodOption) => {
          Text(opt.label).fontSize(13)
            .fontColor(this.sealMood === opt.key ? $r('app.color.on_primary') : $r('app.color.primary'))
            .padding({ left: 10, right: 10, top: 5, bottom: 5 }).borderRadius(10)
            .backgroundColor(this.sealMood === opt.key ? $r('app.color.primary') : $r('app.color.primary_soft'))
            .onClick(() => { this.sealMood = opt.key; })
        })
      }.width('100%')

      // 开启时间
      Row({ space: 8 }) {
        ForEach(CapsuleTimeOptions.OPTIONS, (opt: { label: string; days: number }) => {
          Text(opt.label).fontSize(13)
            .fontColor(this.sealOpenDays === opt.days ? $r('app.color.on_primary') : $r('app.color.primary'))
            .padding({ left: 10, right: 10, top: 5, bottom: 5 }).borderRadius(10)
            .backgroundColor(this.sealOpenDays === opt.days ? $r('app.color.primary') : $r('app.color.primary_soft'))
            .onClick(() => { this.sealOpenDays = opt.days; })
        })
      }.width('100%')

      Button('💛 封存胶囊').width('100%').height(46)
        .fontColor($r('app.color.on_primary')).backgroundColor('#CDA560')
        .borderRadius(14).onClick(() => { this.sealCapsule(); })
    }
    .width('100%').padding(14).borderRadius(16)
    .backgroundColor($r('app.color.surface')).border({ width: 1, color: $r('app.color.outline') })
    .margin({ top: 14, bottom: 10 })
  }

  @Builder
  private buildCapsuleSection(title: string, isSealed: boolean): void {
    const filtered = this.capsules.filter(c => c.isOpened !== isSealed);
    if (filtered.length === 0) return;

    Column({ space: 10 }) {
      Text(title).fontSize(17).fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary')).width('100%').margin({ top: 20, bottom: 4 })

      ForEach(filtered, (capsule: TimeCapsule) => {
        Column({ space: 8 }) {
          Row() {
            Text(isSealed ? '🌱' : '✨').fontSize(18)
            Column({ space: 3 }) {
              Text(capsule.content.length > 25 ? capsule.content.substring(0, 25) + '…' : capsule.content)
                .fontSize(15).fontColor($r('app.color.text_primary')).maxLines(1)
              Text(isSealed ? capsule.remainingText() : `封存于 ${capsule.sealDate}`)
                .fontSize(12).fontColor($r('app.color.text_secondary'))
            }
            .alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text(MoodTypes.getOption(capsule.mood).icon).fontSize(18)
          }.width('100%')
        }
        .width('100%').padding(14).borderRadius(16)
        .backgroundColor($r('app.color.surface'))
        .border({ width: 1, color: $r('app.color.outline') })
        .onClick(() => {
          if (!isSealed) {
            this.readCapsule(capsule);  // 已开启的可以朗读
          }
        })
      }, (capsule: TimeCapsule) => capsule.id.toString())
    }.width('100%')
  }
}
```

### 9.2 CapsuleOpenPage.ets — 开启胶囊仪式页

```typescript
// pages/CapsuleOpenPage.ets

import { TimeCapsule } from '../models/TimeCapsule';
import { TimeCapsuleViewModel } from '../viewmodels/TimeCapsuleViewModel';
import { TimeCapsuleBloomEngine } from '../viewmodels/TimeCapsuleBloomEngine';
import { CapsuleBloomCanvas } from '../components/CapsuleBloomCanvas';
import { CapsuleTtsService } from '../services/CapsuleTtsService';
import { MoodTypes } from '../constants/MoodTypes';
import { TtsService, TtsState } from '../services/TtsService';

/**
 * 胶囊开启仪式页
 *
 * 全屏体验：
 *   1. 花苞绽放动画（~2 秒）
 *   2. 内容渐显 + TTS 自动朗读"过去的信"
 *   3. 朗读控制条（暂停/停止/重新朗读）
 */
@Entry
@Component
struct CapsuleOpenPage {
  @State capsule: TimeCapsule = new TimeCapsule();
  @State loaded: boolean = false;
  @State showContent: boolean = false;
  @State bloomFrame: number = 0;
  @State bloomComplete: boolean = false;
  @State ttsState: TtsState = TtsState.IDLE;
  @State message: string = '';

  private readonly viewModel: TimeCapsuleViewModel = new TimeCapsuleViewModel();
  private readonly tts: TtsService = TtsService.getInstance();
  private animTimer: number = -1;

  aboutToAppear(): void {
    this.loadCapsule();
  }

  private async loadCapsule(): Promise<void> {
    const params = this.getUIContext().getRouter().getParams() as Record<string, number>;
    const capsuleId = params?.['capsuleId'];
    if (typeof capsuleId !== 'number') { this.message = '胶囊信息不完整'; return; }

    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;

    const capsule = await this.viewModel.getCapsule(context, capsuleId);
    if (capsule === undefined) { this.message = '找不到这个胶囊'; return; }

    if (!capsule.isOpened) {
      // 标记开启
      const result = await this.viewModel.open(context, capsuleId);
      if (result.success && result.capsule) {
        this.capsule = result.capsule;
      } else {
        this.message = result.message;
        return;
      }
    } else {
      this.capsule = capsule;
    }

    this.loaded = true;
    this.playBloomAnimation();
  }

  /** 播放花苞绽放动画 */
  private playBloomAnimation(): void {
    const totalFrames = TimeCapsuleBloomEngine.TOTAL_FRAMES;
    let frame = 0;
    this.animTimer = setInterval(() => {
      this.bloomFrame = frame;
      if (frame >= totalFrames - 1) {
        clearInterval(this.animTimer);
        this.animTimer = -1;
        this.bloomComplete = true;
        // 绽放完成后显示内容 + 开始朗读
        setTimeout(() => { this.showContent = true; this.startReading(); }, 400);
        return;
      }
      frame++;
    }, TimeCapsuleBloomEngine.FRAME_INTERVAL);
  }

  /** 开始朗读 */
  private async startReading(): Promise<void> {
    try {
      await this.tts.init();
    } catch (_) { /* 引擎可能已初始化 */ }
    const script = CapsuleTtsService.buildOpenScript(
      this.capsule.sealDate, this.capsule.openDate,
      this.capsule.authorName, this.capsule.content, this.capsule.mood
    );
    this.tts.speak(script);
    this.tts.setOnStateChange((state: TtsState) => { this.ttsState = state; });
  }

  aboutToDisappear(): void {
    if (this.animTimer !== -1) clearInterval(this.animTimer);
    this.tts.stop();
  }

  private goBack(): void { this.getUIContext().getRouter().back(); }

  build() {
    Column({ space: 0 }) {
      Row({ space: 10 }) {
        Text('‹').fontSize(34).fontWeight(FontWeight.Lighter)
          .fontColor($r('app.color.primary'))
          .onClick(() => { this.goBack(); })
        Text('时光胶囊').fontSize(22).fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
      }.width('100%').padding({ left: 20, right: 20, top: 34 })

      if (!this.loaded) {
        StatePanel({ title: '正在寻找胶囊…', stateIcon: '⏳' }).margin({ top: 100 })
      } else {
        Column({ space: 0 }) {
          // 花苞绽放动画区域
          CapsuleBloomCanvas({
            capsuleMood: this.capsule.mood,
            currentFrame: this.bloomFrame
          })
            .width(300).height(320)
            .margin({ top: 20 })

          // 内容区域（动画完成后渐显）
          if (this.showContent) {
            Column({ space: 14 }) {
              Row() {
                Text('📜').fontSize(20)
                Text(`来自 ${this.capsule.sealDate}`).fontSize(15)
                  .fontWeight(FontWeight.Medium).fontColor($r('app.color.text_primary'))
                Blank()
                Text(MoodTypes.getOption(this.capsule.mood).icon).fontSize(18)
              }.width('100%')

              Text(this.capsule.content)
                .fontSize(17).lineHeight(28)
                .fontColor($r('app.color.text_primary')).width('100%')

              // TTS 朗读控制条
              Row({ space: 10 }) {
                if (this.ttsState === TtsState.SPEAKING) {
                  LoadingProgress().width(18).height(18).color($r('app.color.primary'))
                  Text('朗读中…').fontSize(13).fontColor($r('app.color.primary'))
                  Blank()
                  Button('停止').fontSize(12)
                    .fontColor($r('app.color.text_secondary'))
                    .backgroundColor($r('app.color.primary_soft')).borderRadius(10)
                    .onClick(() => { this.tts.stop(); })
                } else {
                  Text('🔊').fontSize(16)
                  Text('重新朗读').fontSize(13).fontColor($r('app.color.primary'))
                  Blank()
                }
              }
              .width('100%').padding(12).borderRadius(14)
              .backgroundColor($r('app.color.primary_soft'))
              .opacity(this.showContent ? 1 : 0)
              .animation({ duration: 600, curve: Curve.EaseIn })
            }
            .width('100%').padding(20).margin({ top: 10 })
            .opacity(this.showContent ? 1 : 0)
            .animation({ duration: 800, curve: Curve.EaseIn })
          }

          if (this.message.length > 0) {
            Text(this.message).fontSize(13).fontColor($r('app.color.error'))
              .width('100%').padding(20)
          }
        }
        .alignItems(HorizontalAlign.Center).width('100%')
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.app_background'))
  }
}
```

---

## 十、路由与配置

### 10.1 AppRoutes.ets 追加

```typescript
static readonly TIME_CAPSULE_GARDEN: string = 'pages/TimeCapsuleGardenPage';
```

### 10.2 main_pages.json 追加

```json
"pages/TimeCapsuleGardenPage",
"pages/CapsuleOpenPage"
```

### 10.3 module.json5 追加权限

```json5
{
  "name": "ohos.permission.NOTIFICATION_CONTROLLER",
  "reason": "$string:notification_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
},
{
  "name": "ohos.permission.READ_CALENDAR",
  "reason": "$string:calendar_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
},
{
  "name": "ohos.permission.WRITE_CALENDAR",
  "reason": "$string:calendar_reason",
  "usedScene": { "abilities": ["EntryAbility"], "when": "always" }
}
```

### 10.4 EntryAbility.ets 增加 onNewWant 处理胶囊跳转

```typescript
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  hilog.info(DOMAIN, TAG, 'onNewWant');
  const targetRoute = want.parameters?.['targetRoute'] as string;
  const capsuleId = want.parameters?.['capsuleId'] as string;
  if (targetRoute === 'capsule_open' && capsuleId) {
    // 跳转到胶囊开启页
    this.context.startAbility({
      bundleName: 'com.example.date',
      abilityName: 'EntryAbility',
      uri: `pages/CapsuleOpenPage?capsuleId=${capsuleId}`
    });
  }
}
```

---

## 十一、后端 API 约定

| 方法 | 路径 | 请求体 | 响应体 | 说明 |
|------|------|--------|--------|------|
| `POST` | `/api/time-capsules` | `{content, mood, openDate}` | `TimeCapsule` | 创建胶囊 |
| `GET` | `/api/time-capsules` | — | `TimeCapsule[]` | 获取我的所有胶囊 |
| `GET` | `/api/time-capsules/:id` | — | `TimeCapsule` | 获取单个胶囊详情 |
| `PATCH` | `/api/time-capsules/:id/open` | `{}` | `TimeCapsule` | 标记胶囊已开启 |

---

## 十二、开发步骤（按顺序执行）

1. 创建 `TimeCapsule.ets` 数据模型 + `CapsuleTimeOptions`
2. 在 `ApiRequests.ets` 追加 `CreateTimeCapsuleRequestBody`
3. 创建 `TimeCapsuleBloomEngine.ets` 动画引擎
4. 创建 `CapsuleReminderService.ets`（通知+日历双通道提醒）
5. 创建 `CapsuleTtsService.ets` 朗读文本构建器
6. 创建 `TimeCapsuleRepository.ets` 仓库层
7. 创建 `TimeCapsuleViewModel.ets` 业务编排
8. 创建 `CapsuleBud.ets` 花苞组件（记忆树展示用）
9. 创建 `CapsuleBloomCanvas.ets` 绽放动画 Canvas 组件
10. 创建 `TimeCapsuleGardenPage.ets` 胶囊花园页面
11. 创建 `CapsuleOpenPage.ets` 仪式感开启页面
12. 配置路由 + 权限 + EntryAbility.onNewWant
13. 可选：修改 `VineTreeCanvas.ets` 在记忆树上渲染花苞节点
14. 对接后端 API
15. 测试验证

---

## 十三、参考资料

| 主题 | 官方文档 |
|------|---------|
| CoreSpeechKit TTS | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/core-speech-kit-guide |
| Notification Kit | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-overview |
| Calendar Kit | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/calendar-kit-overview |
| WantAgent | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wantagent-overview |
| CanvasRenderingContext2D | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-canvasrenderingcontext2d |
| ArkUI 应用开发总指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide |
