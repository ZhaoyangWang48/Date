# 记忆漂流瓶 · Memory Drift Bottle — 开发指导文档

> **适用平台**：HarmonyOS NEXT (API 14+, HarmonyOS 5.0.2)  
> **目标项目**：植忆 (com.example.date)  
> **文档用途**：指导 AI 按照官方规范完成功能开发

---

## 一、功能概述

### 1.1 产品定义

用户将一段记忆"封入漂流瓶"，随机漂流到另一个用户手中。收到的人可以阅读、留下回应（一片"共鸣叶"），但双方始终保持匿名。三天后瓶子自动沉入海底，不再可被捞起。

### 1.2 核心玩法

| 动作 | 描述 | 限制 |
|------|------|------|
| **扔出** | 从已有记忆选择一条，或新写一条，点击"投入大海" | 每人每天最多扔 3 个 |
| **捞起** | 随机获取一条匿名漂流瓶，可阅读内容 | 每人每天限捞 3 次 |
| **共鸣** | 选择一种"共鸣心情"回应（感动/同感/祝福/温暖/想念） | 每个瓶子限回应一次 |
| **沉没** | 3 天后瓶子自动过期，不可再被捞起 | 扔出者仍可见共鸣统计 |

### 1.3 鸿蒙能力运用

| 能力 | 用途 | 对应 Kit |
|------|------|----------|
| 通知服务 | 有人回应了你的漂流瓶 → 通知栏提醒 | `@kit.NotificationKit` |
| WantAgent | 点击通知跳转到"我的共鸣"页面 | `@kit.AbilityKit` |
| Canvas 动画 | 海洋背景波浪 + 漂流瓶浮动动画 | `@kit.ArkUI` Canvas |
| 随机算法 | 每天为用户分配不同的漂流瓶 | 确定性伪随机 |

---

## 二、架构设计

### 2.1 新增文件清单

```
entry/src/main/ets/
├── models/
│   ├── DriftBottle.ets              ← 漂流瓶数据模型
│   └── ResonanceLeaf.ets            ← 共鸣叶数据模型
├── repositories/
│   └── DriftBottleRepository.ets    ← 漂流瓶 API 仓库层
├── viewmodels/
│   └── DriftBottleViewModel.ets     ← 漂流瓶业务编排
├── services/
│   ├── DriftBottleNotification.ets  ← 共鸣通知服务
│   └── DriftRandomEngine.ets        ← 随机分配引擎
├── components/
│   ├── DriftOceanCanvas.ets         ← 海洋背景 Canvas 动画
│   └── ResonanceMoodPicker.ets      ← 共鸣心情选择器
└── pages/
    └── DriftBottlePage.ets          ← 漂流瓶主页面
```

### 2.2 修改文件清单

```
entry/src/main/ets/
├── constants/AppRoutes.ets          ← 新增 DRIFT_BOTTLE 路由
├── pages/MainTabPage.ets            ← 底部导航增加漂流瓶入口
└── entry/src/main/module.json5      ← 新增通知权限
```

### 2.3 数据流

```
用户操作          ViewModel              Repository           后端 API
─────────        ──────────            ────────────          ────────
扔出瓶子  ──→  throwBottle()    ──→  POST /api/bottles     → 存入池中
捞起瓶子  ──→  pickupBottle()   ──→  GET  /api/bottles/random → 随机返回
发送共鸣  ──→  sendResonance()  ──→  POST /api/bottles/:id/resonance → 通知扔出者
查看共鸣  ──→  myResonances()   ──→  GET  /api/bottles/mine/resonances → 共鸣列表
```

---

## 三、数据模型

### 3.1 DriftBottle.ets

```typescript
// models/DriftBottle.ets
/**
 * 漂流瓶数据模型
 *
 * @description 一条被封入漂流瓶的记忆，在用户之间匿名漂流
 */
export class DriftBottle {
  /** 漂流瓶唯一 ID */
  id: number = 0;

  /** 记忆内容（文字） */
  content: string = '';

  /** 心情标签：calm/happy/excited/sad/tired */
  mood: string = 'calm';

  /** 扔出时间（ISO 8601 字符串） */
  throwTime: string = '';

  /** 过期时间 = throwTime + 3 天（ISO 8601 字符串） */
  expireTime: string = '';

  /** 是否已被捞起（非必需字段，用于统计） */
  isPickedUp: boolean = false;

  /** 收到的共鸣数量 */
  resonanceCount: number = 0;

  constructor(
    id: number = 0,
    content: string = '',
    mood: string = 'calm',
    throwTime: string = '',
    expireTime: string = ''
  ) {
    this.id = id;
    this.content = content;
    this.mood = mood;
    this.throwTime = throwTime;
    this.expireTime = expireTime;
  }

  /** 是否已过期（客户端判断） */
  isExpired(): boolean {
    if (!this.expireTime) return false;
    return new Date(this.expireTime).getTime() < Date.now();
  }

  /** 剩余有效天数 */
  remainingDays(): number {
    if (!this.expireTime) return 0;
    const remaining = new Date(this.expireTime).getTime() - Date.now();
    return Math.max(0, Math.ceil(remaining / 86400000));
  }
}
```

### 3.2 ResonanceLeaf.ets

```typescript
// models/ResonanceLeaf.ets
/**
 * 共鸣叶数据模型
 *
 * @description 用户对漂流瓶的匿名情感回应
 */
export class ResonanceLeaf {
  /** 共鸣记录 ID */
  id: number = 0;

  /** 关联的漂流瓶 ID */
  bottleId: number = 0;

  /** 共鸣心情：moved/relatable/blessed/warm/miss */
  mood: string = 'moved';

  /** 共鸣时间（ISO 8601 字符串） */
  timestamp: string = '';

  /** 漂流瓶的内容摘要（仅扔出者可见，用于回忆上下文） */
  bottleContentSnippet: string = '';

  constructor(id: number, bottleId: number, mood: string, timestamp: string, snippet: string = '') {
    this.id = id;
    this.bottleId = bottleId;
    this.mood = mood;
    this.timestamp = timestamp;
    this.bottleContentSnippet = snippet;
  }
}

/**
 * 共鸣心情选项定义
 *
 * 参考植忆已有的 MoodTypes 模式
 */
export class ResonanceMoodOption {
  key: string = '';
  label: string = '';
  icon: string = '';
  color: string = '';

  constructor(key: string, label: string, icon: string, color: string) {
    this.key = key;
    this.label = label;
    this.icon = icon;
    this.color = color;
  }
}

export class ResonanceMoodTypes {
  static readonly OPTIONS: ResonanceMoodOption[] = [
    new ResonanceMoodOption('moved', '感动', '💧', '#7D9DA6'),   // 与记忆的 sad 色系呼应
    new ResonanceMoodOption('relatable', '同感', '🤝', '#6F9D78'), // 与记忆的 calm 色系呼应
    new ResonanceMoodOption('blessed', '祝福', '✨', '#CDA560'),   // 与记忆的 happy 色系呼应
    new ResonanceMoodOption('warm', '温暖', '🕯️', '#C98279'),      // 与记忆的 excited 色系呼应
    new ResonanceMoodOption('miss', '想念', '🌙', '#8E87A2')       // 与记忆的 tired 色系呼应
  ];

  static getOption(key: string): ResonanceMoodOption {
    const option = ResonanceMoodTypes.OPTIONS.find(item => item.key === key);
    return option ?? ResonanceMoodTypes.OPTIONS[0];
  }
}
```

### 3.3 API 请求体（复用已有 ApiRequests.ets 模式）

```typescript
// 在 models/ApiRequests.ets 中追加

/** 扔出漂流瓶请求体 */
export class ThrowBottleRequestBody {
  memoryId: number = 0;   // 从已有记忆选择时传入；0 表示新写
  content: string = '';   // 新写内容（memoryId=0 时必填）
  mood: string = 'calm';

  constructor(memoryId: number, content: string, mood: string) {
    this.memoryId = memoryId;
    this.content = content;
    this.mood = mood;
  }
}

/** 发送共鸣请求体 */
export class SendResonanceRequestBody {
  mood: string = 'moved';

  constructor(mood: string) {
    this.mood = mood;
  }
}
```

---

## 四、服务层

### 4.1 DriftRandomEngine.ets — 随机分配引擎

```typescript
// services/DriftRandomEngine.ets

/**
 * 漂流瓶随机分配引擎
 *
 * 使用确定性伪随机算法（LCG），以当天日期 + 用户 ID 为种子，
 * 保证同一用户在同一天获得相同但唯一的随机序列。
 *
 * 参考：植忆已有的 TreeGrowthEngine.next() LCG 实现
 */
export class DriftRandomEngine {
  /**
   * 生成当天种子
   *
   * @param userId 当前用户 ID
   * @returns 当日确定性种子值
   */
  static dailySeed(userId: number): number {
    const now = new Date();
    const dateKey = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
    // 混合日期和用户 ID，确保每人每天的种子不同
    return ((dateKey * 1664525 + userId * 1013904223) & 0x7fffffff) >>> 0;
  }

  /**
   * LCG 伪随机数生成器（与 TreeGrowthEngine 同款算法）
   *
   * @param state 当前状态值
   * @returns 下一个伪随机状态值（非负整数）
   */
  static next(state: number): number {
    return ((state * 1664525 + 1013904223) & 0x7fffffff) >>> 0;
  }

  /**
   * 将 LCG 状态转换为 [0, 1) 之间的浮点数
   *
   * @param state LCG 状态值
   * @returns [0, 1) 之间的伪随机浮点数
   */
  static toFloat(state: number): number {
    return (state % 1000000) / 1000000;
  }

  /**
   * 判断今天是否还有捞取次数
   *
   * @param pickedCount 今天已捞取次数
   * @param maxPerDay 每日最大捞取次数（默认 3）
   */
  static canPickup(pickedCount: number, maxPerDay: number = 3): boolean {
    return pickedCount < maxPerDay;
  }
}
```

### 4.2 DriftBottleNotification.ets — 共鸣通知服务

```typescript
// services/DriftBottleNotification.ets

import { notificationManager } from '@kit.NotificationKit';
import { wantAgent, WantAgent } from '@kit.AbilityKit';
import { Context } from '@kit.AbilityKit';
import { AppRoutes } from '../constants/AppRoutes';

/**
 * 漂流瓶通知服务
 *
 * 当有人对你的漂流瓶发送了共鸣，通过通知栏提醒。
 *
 * 官方参考：
 * - Notification Kit: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-overview
 * - WantAgent: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wantagent-overview
 */
export class DriftBottleNotification {
  /**
   * 发送共鸣通知
   *
   * @param context 应用上下文
   * @param resonanceCount 当前未读共鸣总数
   * @param latestMood 最新一条共鸣的心情类型
   */
  static async sendResonanceNotification(
    context: Context,
    resonanceCount: number,
    latestMood: string
  ): Promise<void> {
    // 步骤 1：创建 WantAgent，点击通知后跳转到漂流瓶页面
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.example.date',
          abilityName: 'EntryAbility',
          parameters: {
            targetRoute: AppRoutes.DRIFT_BOTTLE,  // 跳转到漂流瓶页面
            targetTab: 'my_resonances'             // 直接打开"我的共鸣"标签
          }
        }
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 2001,  // 漂流瓶共鸣通知的请求码
      wantAgentFlags: [wantAgent.WantAgentFlags.CONSTANT_FLAG]
    };

    const agent: WantAgent = await wantAgent.getWantAgent(wantAgentInfo);

    // 步骤 2：获取共鸣心情的显示文案
    const moodLabels: Record<string, string> = {
      'moved': '感动',
      'relatable': '同感',
      'blessed': '祝福',
      'warm': '温暖',
      'miss': '想念'
    };
    const moodLabel = moodLabels[latestMood] ?? '共鸣';

    // 步骤 3：构建通知并发布
    const notificationRequest: notificationManager.NotificationRequest = {
      id: 2001,  // 漂流瓶共鸣通知统一 ID（重复 ID 会覆盖旧通知）
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: '🌊 有人回应了你的漂流瓶',
          text: resonanceCount === 1
            ? `收到 1 片${moodLabel}的共鸣叶`
            : `收到 ${resonanceCount} 片共鸣叶，最新是${moodLabel}`,
          additionalText: '点击查看'
        }
      },
      notificationSlotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
      wantAgent: agent,
      isOngoing: false
    };

    try {
      await notificationManager.publish(notificationRequest);
      console.info('[DriftBottle] 共鸣通知已发送');
    } catch (err) {
      console.error(`[DriftBottle] 通知发送失败: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 清除漂流瓶相关的所有通知
   */
  static async clearNotifications(): Promise<void> {
    try {
      await notificationManager.cancel(2001);
      console.info('[DriftBottle] 通知已清除');
    } catch (err) {
      console.error(`[DriftBottle] 通知清除失败: ${JSON.stringify(err)}`);
    }
  }
}
```

---

## 五、仓库层

### 5.1 DriftBottleRepository.ets

```typescript
// repositories/DriftBottleRepository.ets

import { DriftBottle } from '../models/DriftBottle';
import { ResonanceLeaf } from '../models/ResonanceLeaf';
import { ApiResult } from '../models/ApiResult';
import { Context } from '@kit.AbilityKit';
import { HttpClient } from '../services/HttpClient';
import { TokenStorage } from '../services/TokenStorage';
import { ApiConfig } from '../constants/ApiConfig';
import { ThrowBottleRequestBody, SendResonanceRequestBody } from '../models/ApiRequests';

/**
 * 漂流瓶仓库层
 *
 * 负责与后端的漂流瓶 API 通信。
 * 遵循植忆已有的 Repository 模式（参见 AuthRepository、MemoryRepository）。
 *
 * API 端点（需后端配合实现）：
 * - POST   /api/bottles                → 扔出漂流瓶
 * - GET    /api/bottles/random          → 随机捞取一个瓶子
 * - POST   /api/bottles/:id/resonance   → 发送共鸣
 * - GET    /api/bottles/mine            → 我扔出的瓶子列表
 * - GET    /api/bottles/mine/resonances → 我收到的共鸣列表
 * - GET    /api/bottles/pickup-count    → 今日捞取次数
 */
export class DriftBottleRepository {
  private readonly http: HttpClient = new HttpClient();

  // ----- API 路径常量 -----
  private static readonly BOTTLES: string = '/api/bottles';
  private static readonly BOTTLES_RANDOM: string = '/api/bottles/random';
  private static readonly BOTTLES_MINE: string = '/api/bottles/mine';
  private static readonly BOTTLES_RESONANCES: string = '/api/bottles/mine/resonances';
  private static readonly BOTTLES_PICKUP_COUNT: string = '/api/bottles/pickup-count';

  /**
   * 扔出漂流瓶
   *
   * @param context   应用上下文
   * @param memoryId  从已有记忆选择时传入；0 表示新写
   * @param content   新写内容（memoryId=0 时必填）
   * @param mood      心情标签
   */
  async throwBottle(
    context: Context, memoryId: number, content: string, mood: string
  ): Promise<ApiResult<DriftBottle>> {
    const token = await TokenStorage.getToken(context);
    const body = new ThrowBottleRequestBody(memoryId, content, mood);
    return this.toBottle(
      await this.http.post<DriftBottle>(DriftBottleRepository.BOTTLES, body, token)
    );
  }

  /**
   * 随机捞取一个漂流瓶
   */
  async pickupRandom(context: Context): Promise<ApiResult<DriftBottle>> {
    const token = await TokenStorage.getToken(context);
    return this.toBottle(
      await this.http.get<DriftBottle>(DriftBottleRepository.BOTTLES_RANDOM, token)
    );
  }

  /**
   * 对某个漂流瓶发送共鸣
   *
   * @param context  应用上下文
   * @param bottleId 漂流瓶 ID
   * @param mood     共鸣心情
   */
  async sendResonance(
    context: Context, bottleId: number, mood: string
  ): Promise<ApiResult<ResonanceLeaf>> {
    const token = await TokenStorage.getToken(context);
    const body = new SendResonanceRequestBody(mood);
    const path = `${DriftBottleRepository.BOTTLES}/${bottleId}/resonance`;
    return this.toResonance(
      await this.http.post<ResonanceLeaf>(path, body, token)
    );
  }

  /**
   * 获取我扔出的瓶子列表
   */
  async listMyBottles(context: Context): Promise<ApiResult<DriftBottle[]>> {
    const token = await TokenStorage.getToken(context);
    return this.toBottles(
      await this.http.get<DriftBottle[]>(DriftBottleRepository.BOTTLES_MINE, token)
    );
  }

  /**
   * 获取我收到的共鸣列表
   */
  async listMyResonances(context: Context): Promise<ApiResult<ResonanceLeaf[]>> {
    const token = await TokenStorage.getToken(context);
    return this.toResonances(
      await this.http.get<ResonanceLeaf[]>(DriftBottleRepository.BOTTLES_RESONANCES, token)
    );
  }

  /**
   * 获取今日已捞取次数
   */
  async getTodayPickupCount(context: Context): Promise<ApiResult<number>> {
    const token = await TokenStorage.getToken(context);
    const result = await this.http.get<{count: number}>(
      DriftBottleRepository.BOTTLES_PICKUP_COUNT, token
    );
    if (result.data !== undefined) {
      return new ApiResult<number>(result.code, result.message, result.data.count);
    }
    return new ApiResult<number>(result.code, result.message, 0);
  }

  // ----- 数据规范化（遵循 MemoryRepository 的 toMemory/toMemories 模式）-----

  private toBottle(result: ApiResult<DriftBottle>): ApiResult<DriftBottle> {
    if (result.data === undefined) return result;
    const b = result.data;
    return new ApiResult<DriftBottle>(result.code, result.message,
      new DriftBottle(b.id, b.content, b.mood, b.throwTime, b.expireTime));
  }

  private toBottles(result: ApiResult<DriftBottle[]>): ApiResult<DriftBottle[]> {
    if (result.data === undefined) return result;
    return new ApiResult<DriftBottle[]>(result.code, result.message,
      result.data.map(b => new DriftBottle(b.id, b.content, b.mood, b.throwTime, b.expireTime)));
  }

  private toResonance(result: ApiResult<ResonanceLeaf>): ApiResult<ResonanceLeaf> {
    if (result.data === undefined) return result;
    const r = result.data;
    return new ApiResult<ResonanceLeaf>(result.code, result.message,
      new ResonanceLeaf(r.id, r.bottleId, r.mood, r.timestamp, r.bottleContentSnippet));
  }

  private toResonances(result: ApiResult<ResonanceLeaf[]>): ApiResult<ResonanceLeaf[]> {
    if (result.data === undefined) return result;
    return new ApiResult<ResonanceLeaf[]>(result.code, result.message,
      result.data.map(r => new ResonanceLeaf(r.id, r.bottleId, r.mood, r.timestamp, r.bottleContentSnippet)));
  }
}
```

---

## 六、ViewModel 层

### 6.1 DriftBottleViewModel.ets

```typescript
// viewmodels/DriftBottleViewModel.ets

import { DriftBottle } from '../models/DriftBottle';
import { ResonanceLeaf, ResonanceMoodTypes } from '../models/ResonanceLeaf';
import { DriftBottleRepository } from '../repositories/DriftBottleRepository';
import { DriftRandomEngine } from '../services/DriftRandomEngine';
import { Context } from '@kit.AbilityKit';

/**
 * 漂流瓶操作结果
 *
 * 遵循植忆已有的 ActionResult 模式（参见 AuthActionResult、MemoryActionResult）
 */
export class DriftBottleActionResult {
  success: boolean = false;
  message: string = '';
  data: DriftBottle | ResonanceLeaf | undefined = undefined;

  constructor(success: boolean, message: string, data?: DriftBottle | ResonanceLeaf) {
    this.success = success;
    this.message = message;
    this.data = data;
  }
}

/**
 * 漂流瓶 ViewModel
 *
 * 负责漂流瓶业务逻辑编排
 */
export class DriftBottleViewModel {
  private readonly repository: DriftBottleRepository = new DriftBottleRepository();

  // ----- 扔出漂流瓶 -----

  /**
   * 扔出漂流瓶
   *
   * @param context  应用上下文
   * @param memoryId 已有记忆 ID（0 表示新写）
   * @param content  新写内容
   * @param mood     心情标签
   */
  async throwBottle(
    context: Context, memoryId: number, content: string, mood: string
  ): Promise<DriftBottleActionResult> {
    // 校验：必须提供已有记忆 ID 或新写内容
    if (memoryId === 0 && content.trim().length === 0) {
      return new DriftBottleActionResult(false, '请选择一段记忆或写下此刻的想法');
    }

    const result = await this.repository.throwBottle(context, memoryId, content.trim(), mood);
    if (result.code !== 200 || result.data === undefined) {
      return new DriftBottleActionResult(false, result.message || '漂流瓶未能投入大海，请重试');
    }

    return new DriftBottleActionResult(true, '漂流瓶已投入大海 🌊', result.data);
  }

  // ----- 捞起漂流瓶 -----

  /**
   * 随机捞取一个漂流瓶
   *
   * 每日限捞 3 次，由后端控制。
   */
  async pickupBottle(context: Context): Promise<DriftBottleActionResult> {
    // 先从后端获取今日已捞取次数（后端做最终校验）
    const countResult = await this.repository.getTodayPickupCount(context);

    if (countResult.data !== undefined && !DriftRandomEngine.canPickup(countResult.data)) {
      return new DriftBottleActionResult(false, '今天的 3 次捞取机会已用完，明天再来吧 🌊');
    }

    const result = await this.repository.pickupRandom(context);
    if (result.code === 404 || (result.code === 200 && result.data === undefined)) {
      return new DriftBottleActionResult(false, '海面上暂时没有漂流瓶，过会儿再来看看');
    }
    if (result.code !== 200 || result.data === undefined) {
      return new DriftBottleActionResult(false, result.message || '捞取失败，请重试');
    }

    return new DriftBottleActionResult(true, '捞到一个漂流瓶！', result.data);
  }

  // ----- 发送共鸣 -----

  /**
   * 对漂流瓶发送共鸣
   */
  async sendResonance(
    context: Context, bottleId: number, mood: string
  ): Promise<DriftBottleActionResult> {
    if (!ResonanceMoodTypes.getOption(mood)) {
      return new DriftBottleActionResult(false, '请选择一种共鸣心情');
    }

    const result = await this.repository.sendResonance(context, bottleId, mood);
    if (result.code !== 200 || result.data === undefined) {
      return new DriftBottleActionResult(false, result.message || '共鸣未能送出，请重试');
    }

    const moodLabel = ResonanceMoodTypes.getOption(mood).label;
    return new DriftBottleActionResult(true, `你送出了一片「${moodLabel}」的共鸣叶`, result.data);
  }

  // ----- 列表查询 -----

  /**
   * 获取我扔出的瓶子列表
   */
  async listMyBottles(context: Context): Promise<DriftBottle[]> {
    const result = await this.repository.listMyBottles(context);
    return result.data ?? [];
  }

  /**
   * 获取我收到的共鸣列表
   */
  async listMyResonances(context: Context): Promise<ResonanceLeaf[]> {
    const result = await this.repository.listMyResonances(context);
    return result.data ?? [];
  }

  /**
   * 获取今日捞取次数
   */
  async getTodayPickupCount(context: Context): Promise<number> {
    const result = await this.repository.getTodayPickupCount(context);
    return result.data ?? 0;
  }
}
```

---

## 七、Canvas 组件

### 7.1 DriftOceanCanvas.ets — 海洋背景动画

```typescript
// components/DriftOceanCanvas.ets

/**
 * 漂流瓶海洋背景 Canvas 动画
 *
 * 渲染多层波浪 + 星空 + 偶现月光反射。
 *
 * 参考：
 * - CanvasRenderingContext2D 官方文档:
 *   https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-canvasrenderingcontext2d
 * - 植忆已有的 VineTreeCanvas.ets 实现模式
 *
 * 动画机制：
 * - 使用 setInterval 驱动帧循环（~33ms/帧 ≈ 30 FPS）
 * - HarmonyOS NEXT 中 requestAnimationFrame 支持不完整，采用 setInterval 替代
 * - 在 aboutToDisappear 中必须清理定时器
 *
 * 性能优化：
 * - 使用 RenderingContextSettings(true) 启用硬件加速
 * - 波浪计算仅使用简单 sin/cos，避免复杂路径操作
 * - 星点一次预计算位置，不在每帧重新随机
 */
@Component
export struct DriftOceanCanvas {
  /** 动画是否运行中 */
  @Prop isAnimating: boolean = true;
  /** 容器宽度 */
  @Prop canvasWidth: number = 360;
  /** 容器高度 */
  @Prop canvasHeight: number = 480;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private animationTimer: number = -1;
  private frameCount: number = 0;

  // 预计算的星点位置（初始化时生成，之后不变）
  private stars: { x: number; y: number; r: number; alpha: number }[] = [];

  aboutToAppear(): void {
    // 预计算 30 颗星点的位置
    for (let i = 0; i < 30; i++) {
      this.stars.push({
        x: (i * 137 + 53) % this.canvasWidth,
        y: (i * 89 + 31) % (this.canvasHeight * 0.55),
        r: (i % 3 === 0) ? 1.5 : 0.8,
        alpha: 0.3 + (i % 10) * 0.06
      });
    }
  }

  build() {
    Canvas(this.context)
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .onReady(() => {
        this.drawFrame(0);
        if (this.isAnimating) {
          this.startAnimation();
        }
      })
  }

  /** 启动动画循环（~30 FPS） */
  startAnimation(): void {
    if (this.animationTimer !== -1) return;
    this.animationTimer = setInterval(() => {
      this.frameCount++;
      this.drawFrame(this.frameCount);
    }, 33);  // ~30 FPS
  }

  /** 停止动画 */
  stopAnimation(): void {
    if (this.animationTimer !== -1) {
      clearInterval(this.animationTimer);
      this.animationTimer = -1;
    }
  }

  aboutToDisappear(): void {
    this.stopAnimation();
  }

  /** 绘制一帧 */
  private drawFrame(frame: number): void {
    const w = this.canvasWidth;
    const h = this.canvasHeight;

    // 1. 天空渐变背景
    const skyGrad = this.context.createLinearGradient(0, 0, 0, h);
    skyGrad.addColorStop(0, '#0A1628');     // 夜空顶部
    skyGrad.addColorStop(0.45, '#142240');  // 夜空中部
    skyGrad.addColorStop(0.65, '#1A3A5C');  // 海天交界
    skyGrad.addColorStop(0.8, '#0D2847');   // 浅海
    skyGrad.addColorStop(1, '#061220');     // 深海
    this.context.fillStyle = skyGrad;
    this.context.fillRect(0, 0, w, h);

    // 2. 星星
    for (const star of this.stars) {
      const twinkle = star.alpha + Math.sin(frame * 0.03 + star.x) * 0.15;
      this.context.globalAlpha = Math.max(0.1, Math.min(1, twinkle));
      this.context.fillStyle = '#D4E8FF';
      this.context.beginPath();
      this.context.arc(star.x, star.y, star.r, 0, Math.PI * 2);
      this.context.fill();
    }
    this.context.globalAlpha = 1;

    // 3. 月光反射（偶现）
    if (frame % 180 < 60) {
      const moonAlpha = 0.15 + Math.sin((frame % 60) / 60 * Math.PI) * 0.1;
      this.context.globalAlpha = moonAlpha;
      this.context.fillStyle = '#D4C89A';
      this.context.beginPath();
      this.context.ellipse(w * 0.7, h * 0.12, 40, 18, 0, 0, Math.PI * 2);
      this.context.fill();
      this.context.globalAlpha = moonAlpha * 0.6;
      this.context.fillStyle = '#D4C89A';
      this.context.beginPath();
      this.context.ellipse(w * 0.7, h * 0.12, 58, 26, 0, 0, Math.PI * 2);
      this.context.fill();
      this.context.globalAlpha = 1;
    }

    // 4. 四层波浪（从远到近）
    const waveLayers = [
      { yBase: h * 0.58, amp: 8,  freq: 0.012, speed: 0.025, color: '#1A4070', alpha: 0.7 },
      { yBase: h * 0.66, amp: 12, freq: 0.018, speed: 0.030, color: '#1B5080', alpha: 0.8 },
      { yBase: h * 0.76, amp: 14, freq: 0.020, speed: 0.035, color: '#1C5A8C', alpha: 0.85 },
      { yBase: h * 0.88, amp: 16, freq: 0.022, speed: 0.040, color: '#1E6098', alpha: 0.9 }
    ];

    for (const layer of waveLayers) {
      this.context.globalAlpha = layer.alpha;
      this.context.fillStyle = layer.color;
      this.context.beginPath();
      this.context.moveTo(0, h);

      for (let x = 0; x <= w; x += 3) {
        const y = layer.yBase
          + Math.sin(x * layer.freq + frame * layer.speed) * layer.amp
          + Math.sin(x * layer.freq * 2.7 + frame * layer.speed * 0.7) * layer.amp * 0.4;
        this.context.lineTo(x, y);
      }

      this.context.lineTo(w, h);
      this.context.closePath();
      this.context.fill();
    }

    this.context.globalAlpha = 1;
  }
}
```

---

## 八、组件

### 8.1 ResonanceMoodPicker.ets — 共鸣心情选择器

```typescript
// components/ResonanceMoodPicker.ets

import { ResonanceMoodOption, ResonanceMoodTypes } from '../models/ResonanceLeaf';

/**
 * 共鸣心情选择器组件
 *
 * 用户在捞到漂流瓶后，选择一种心情来回应。
 * 设计模式遵循植忆已有的 MoodSelector.ets。
 */
@Component
export struct ResonanceMoodPicker {
  @Prop selectedMood: string = 'moved';
  onMoodSelected: (mood: string) => void = () => {};

  build() {
    Column({ space: 10 }) {
      Text('选择你的共鸣')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .width('100%')

      Text('你的回应会匿名送达扔出瓶子的人')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')

      // 使用 Wrap 布局让心情选项自动换行（5 个选项）
      Row({ space: 8 }) {
        ForEach(ResonanceMoodTypes.OPTIONS, (option: ResonanceMoodOption) => {
          Column({ space: 4 }) {
            Text(option.icon)
              .fontSize(28)
            Text(option.label)
              .fontSize(12)
              .fontColor(
                this.selectedMood === option.key
                  ? $r('app.color.on_primary')
                  : $r('app.color.text_secondary')
              )
          }
          .width(56)
          .height(72)
          .justifyContent(FlexAlign.Center)
          .borderRadius(14)
          .backgroundColor(
            this.selectedMood === option.key
              ? option.color
              : $r('app.color.surface')
          )
          .border({
            width: this.selectedMood === option.key ? 0 : 1,
            color: $r('app.color.outline')
          })
          .onClick(() => {
            this.onMoodSelected(option.key);
          })
        }, (option: ResonanceMoodOption) => option.key)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor($r('app.color.surface'))
    .border({ width: 1, color: $r('app.color.outline') })
  }
}
```

---

## 九、页面

### 9.1 DriftBottlePage.ets — 漂流瓶主页面

```typescript
// pages/DriftBottlePage.ets

import { DriftBottle } from '../models/DriftBottle';
import { ResonanceLeaf } from '../models/ResonanceLeaf';
import { DriftBottleViewModel } from '../viewmodels/DriftBottleViewModel';
import { DriftOceanCanvas } from '../components/DriftOceanCanvas';
import { ResonanceMoodPicker } from '../components/ResonanceMoodPicker';
import { StatePanel } from '../components/StatePanel';
import { MoodTypes } from '../constants/MoodTypes';

/**
 * 漂流瓶主页面
 *
 * 页面布局：顶部 Tab 切换（扔出 / 捞起 / 我的共鸣）
 * 每个 Tab 有独立的操作区域。
 *
 * 设计模式遵循植忆已有的 SharedTreePage.ets 多状态页面模式。
 */
@Entry
@Component
struct DriftBottlePage {
  // ----- 页面状态 -----
  @State activeTab: number = 0;  // 0=扔出, 1=捞起, 2=我的共鸣
  @State loading: boolean = false;
  @State message: string = '';
  @State showOcean: boolean = true;

  // ----- 扔出相关状态 -----
  @State throwContent: string = '';
  @State throwMood: string = 'calm';
  @State todayThrowCount: number = 0;

  // ----- 捞起相关状态 -----
  @State currentBottle: DriftBottle | undefined = undefined;
  @State todayPickupCount: number = 0;
  @State selectedResonanceMood: string = 'moved';
  @State resonanceSent: boolean = false;

  // ----- 我的共鸣状态 -----
  @State myBottles: DriftBottle[] = [];
  @State myResonances: ResonanceLeaf[] = [];

  private readonly viewModel: DriftBottleViewModel = new DriftBottleViewModel();

  aboutToAppear(): void {
    this.initialize();
  }

  private async initialize(): Promise<void> {
    this.loading = true;
    try {
      const context = this.getUIContext().getHostContext();
      if (context === undefined) throw new Error('context missing');
      this.todayPickupCount = await this.viewModel.getTodayPickupCount(context);
      this.myBottles = await this.viewModel.listMyBottles(context);
      this.myResonances = await this.viewModel.listMyResonances(context);
      this.todayThrowCount = this.myBottles.filter(
        (b: DriftBottle) => this.isToday(b.throwTime)
      ).length;
    } catch (error) {
      this.message = '加载漂流瓶数据失败，请稍后重试';
    }
    this.loading = false;
  }

  // ----- 扔出 -----
  private async throwBottle(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;

    this.loading = true;
    this.message = '';
    const result = await this.viewModel.throwBottle(context, 0, this.throwContent, this.throwMood);
    this.loading = false;

    if (result.success) {
      this.message = result.message;
      this.throwContent = '';
      this.todayThrowCount += 1;
      // 刷新列表
      this.myBottles = await this.viewModel.listMyBottles(context);
    } else {
      this.message = result.message;
    }
  }

  // ----- 捞起 -----
  private async pickupBottle(): Promise<void> {
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;

    this.loading = true;
    this.message = '';
    this.resonanceSent = false;
    const result = await this.viewModel.pickupBottle(context);
    this.loading = false;

    if (result.success && result.data instanceof DriftBottle) {
      this.currentBottle = result.data;
      this.todayPickupCount += 1;
    } else {
      this.message = result.message;
      this.currentBottle = undefined;
    }
  }

  // ----- 发送共鸣 -----
  private async sendResonance(): Promise<void> {
    if (this.currentBottle === undefined) return;
    const context = this.getUIContext().getHostContext();
    if (context === undefined) return;

    this.loading = true;
    const result = await this.viewModel.sendResonance(
      context, this.currentBottle.id, this.selectedResonanceMood
    );
    this.loading = false;

    if (result.success) {
      this.resonanceSent = true;
      this.message = result.message;
    } else {
      this.message = result.message;
    }
  }

  // ----- 辅助方法 -----
  private isToday(dateStr: string): boolean {
    if (!dateStr) return false;
    const d = new Date(dateStr);
    const now = new Date();
    return d.getFullYear() === now.getFullYear()
      && d.getMonth() === now.getMonth()
      && d.getDate() === now.getDate();
  }

  private goBack(): void {
    this.getUIContext().getRouter().back();
  }

  // ========== UI 构建 ==========

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 海洋背景动画
      DriftOceanCanvas({
        isAnimating: this.showOcean,
        canvasWidth: 360,
        canvasHeight: 480
      })

      // 前景内容
      Scroll() {
        Column({ space: 0 }) {
          // 顶部导航
          Row({ space: 10 }) {
            Text('‹')
              .fontSize(34)
              .fontWeight(FontWeight.Lighter)
              .fontColor('#D4E8FF')
              .onClick(() => { this.goBack(); })
            Text('🌊 漂流瓶')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width('100%')
          .margin({ bottom: 20 })

          // Tab 切换
          Row({ space: 0 }) {
            Button('扔出')
              .layoutWeight(1).fontSize(14)
              .fontColor(this.activeTab === 0 ? '#FFFFFF' : '#D4E8FF')
              .backgroundColor(this.activeTab === 0 ? '#1E609830' : '#FFFFFF10')
              .borderRadius(12).onClick(() => { this.activeTab = 0; })
            Button('捞起')
              .layoutWeight(1).fontSize(14)
              .fontColor(this.activeTab === 1 ? '#FFFFFF' : '#D4E8FF')
              .backgroundColor(this.activeTab === 1 ? '#1E609830' : '#FFFFFF10')
              .borderRadius(12).onClick(() => { this.activeTab = 1; })
            Button('我的共鸣')
              .layoutWeight(1).fontSize(14)
              .fontColor(this.activeTab === 2 ? '#FFFFFF' : '#D4E8FF')
              .backgroundColor(this.activeTab === 2 ? '#1E609830' : '#FFFFFF10')
              .borderRadius(12).onClick(() => { this.activeTab = 2; })
          }
          .width('100%')
          .margin({ bottom: 18 })

          // ===== Tab 0: 扔出漂流瓶 =====
          if (this.activeTab === 0) {
            this.buildThrowTab()
          }

          // ===== Tab 1: 捞起漂流瓶 =====
          if (this.activeTab === 1) {
            this.buildPickupTab()
          }

          // ===== Tab 2: 我的共鸣 =====
          if (this.activeTab === 2) {
            this.buildMyResonanceTab()
          }

          // 通用消息提示
          if (this.message.length > 0) {
            Text(this.message)
              .fontSize(13)
              .fontColor('#D4E8FF')
              .margin({ top: 14 })
              .width('100%')
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ left: 20, right: 20, top: 38, bottom: 32 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
  }

  /** 扔出 Tab UI */
  @Builder
  private buildThrowTab(): void {
    Column({ space: 14 }) {
      Text('把一段记忆封入瓶中，投入大海')
        .fontSize(14)
        .fontColor('#B8D4E8')
        .width('100%')

      Text(`今日已扔出 ${this.todayThrowCount}/3 个`)
        .fontSize(12)
        .fontColor('#8BB8D8')
        .width('100%')

      TextArea({ placeholder: '写下你想说的话…', text: this.throwContent })
        .height(130)
        .padding(14)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#FFFFFF12')
        .border({ width: 1, color: '#FFFFFF20' })
        .borderRadius(14)
        .onChange((value: string) => { this.throwContent = value; })

      // 心情选择（复用已有 MoodSelector 的设计）
      Text('选择心情')
        .fontSize(13)
        .fontColor('#B8D4E8')
        .width('100%')

      Row({ space: 8 }) {
        ForEach(MoodTypes.OPTIONS, (option: MoodOption) => {
          Text(option.label)
            .fontSize(13)
            .fontColor(this.throwMood === option.key ? '#FFFFFF' : '#B8D4E8')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(12)
            .backgroundColor(
              this.throwMood === option.key ? '#1E609860' : '#FFFFFF10'
            )
            .onClick(() => { this.throwMood = option.key; })
        })
      }
      .width('100%')

      Button(this.loading ? '投入中…' : '🌊 投入大海')
        .width('100%')
        .height(48)
        .enabled(!this.loading && this.todayThrowCount < 3)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor('#1E6098')
        .borderRadius(16)
        .onClick(() => { this.throwBottle(); })
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#FFFFFF0C')
  }

  /** 捞起 Tab UI */
  @Builder
  private buildPickupTab(): void {
    Column({ space: 14 }) {
      Text(`今日剩余捞取 ${Math.max(0, 3 - this.todayPickupCount)}/3 次`)
        .fontSize(12)
        .fontColor('#8BB8D8')
        .width('100%')

      if (this.currentBottle === undefined) {
        // 未捞起状态：显示捞取按钮
        Column({ space: 12 }) {
          Text('🫧')
            .fontSize(48)
          Text('海面上漂浮着未知的漂流瓶')
            .fontSize(15)
            .fontColor('#D4E8FF')
          Text('每个瓶子都装着一个陌生人的故事')
            .fontSize(12)
            .fontColor('#8BB8D8')

          Button(this.loading ? '捞取中…' : '🎣 捞一个看看')
            .width('100%')
            .height(48)
            .enabled(!this.loading && this.todayPickupCount < 3)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor('#1E6098')
            .borderRadius(16)
            .onClick(() => { this.pickupBottle(); })
        }
        .width('100%')
        .padding(24)
        .alignItems(HorizontalAlign.Center)
      } else {
        // 已捞起状态：显示漂流瓶内容
        Column({ space: 14 }) {
          // 瓶中信内容
          Column({ space: 10 }) {
            Text('📜 瓶中信')
              .fontSize(13)
              .fontColor('#8BB8D8')
            Text(this.currentBottle.content)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .lineHeight(26)
              .width('100%')
            Row({ space: 6 }) {
              Text(MoodTypes.getOption(this.currentBottle.mood).icon)
                .fontSize(14)
              Text(MoodTypes.getOption(this.currentBottle.mood).label)
                .fontSize(12)
                .fontColor('#B8D4E8')
              Blank()
              Text(`${this.currentBottle.remainingDays()} 天后沉入海底`)
                .fontSize(11)
                .fontColor('#8BB8D8')
            }
            .width('100%')
          }
          .width('100%')
          .padding(18)
          .borderRadius(16)
          .backgroundColor('#FFFFFF10')
          .border({ width: 1, color: '#FFFFFF18' })

          // 共鸣心情选择器（未发送时显示）
          if (!this.resonanceSent) {
            ResonanceMoodPicker({
              selectedMood: this.selectedResonanceMood,
              onMoodSelected: (mood: string) => { this.selectedResonanceMood = mood; }
            })

            Button(this.loading ? '发送中…' : '💚 送出共鸣叶')
              .width('100%')
              .height(44)
              .enabled(!this.loading)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor('#174A6E')
              .borderRadius(14)
              .onClick(() => { this.sendResonance(); })
          } else {
            Text('共鸣叶已送出 ✓')
              .fontSize(14)
              .fontColor('#91B8A3')
              .width('100%')
              .textAlign(TextAlign.Center)
          }

          Button('再捞一个')
            .width('100%')
            .height(44)
            .fontSize(14)
            .fontColor('#D4E8FF')
            .backgroundColor('#FFFFFF0C')
            .borderRadius(14)
            .onClick(() => {
              this.currentBottle = undefined;
              this.resonanceSent = false;
              this.pickupBottle();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .borderRadius(18)
    .backgroundColor('#FFFFFF0C')
  }

  /** 我的共鸣 Tab UI */
  @Builder
  private buildMyResonanceTab(): void {
    Column({ space: 14 }) {
      Text('我扔出的瓶子')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .width('100%')

      if (this.myBottles.length === 0) {
        StatePanel({
          title: '还没有扔出过漂流瓶',
          description: '把你的一段记忆封入瓶中，让它漂向远方',
          stateIcon: '🫧'
        })
      } else {
        ForEach(this.myBottles, (bottle: DriftBottle) => {
          Column({ space: 6 }) {
            Row() {
              Text(bottle.content.length > 20
                ? bottle.content.substring(0, 20) + '…'
                : bottle.content)
                .fontSize(14)
                .fontColor('#FFFFFF')
                .maxLines(1)
                .layoutWeight(1)
              Blank()
              // 共鸣计数
              Row({ space: 4 }) {
                Text('🍂')
                  .fontSize(12)
                Text(`${bottle.resonanceCount}`)
                  .fontSize(12)
                  .fontColor('#CDA560')
              }
            }
            .width('100%')

            Row() {
              Text(bottle.isExpired() ? '已沉入海底' : `${bottle.remainingDays()} 天后沉入海底`)
                .fontSize(11)
                .fontColor(bottle.isExpired() ? '#8E87A2' : '#8BB8D8')
              Blank()
              Text(MoodTypes.getOption(bottle.mood).icon)
                .fontSize(12)
            }
            .width('100%')
          }
          .width('100%')
          .padding(14)
          .borderRadius(14)
          .backgroundColor('#FFFFFF0C')
          .border({ width: 1, color: '#FFFFFF10' })
        }, (bottle: DriftBottle) => bottle.id.toString())
      }

      // 共鸣记录
      if (this.myResonances.length > 0) {
        Text('收到的共鸣')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#FFFFFF')
          .width('100%')
          .margin({ top: 16 })

        ForEach(this.myResonances, (resonance: ResonanceLeaf) => {
          Row({ space: 10 }) {
            Text(ResonanceMoodTypes.getOption(resonance.mood).icon)
              .fontSize(20)
            Column({ space: 2 }) {
              Text(ResonanceMoodTypes.getOption(resonance.mood).label)
                .fontSize(14)
                .fontColor('#FFFFFF')
              Text(resonance.bottleContentSnippet.length > 0
                ? `回应了："${resonance.bottleContentSnippet.substring(0, 15)}…"`
                : '有人回应了你的漂流瓶')
                .fontSize(11)
                .fontColor('#8BB8D8')
            }
            .alignItems(HorizontalAlign.Start)
            Blank()
            Text(this.formatTime(resonance.timestamp))
              .fontSize(10)
              .fontColor('#607080')
          }
          .width('100%')
          .padding(12)
          .borderRadius(12)
          .backgroundColor('#FFFFFF08')
        }, (resonance: ResonanceLeaf) => resonance.id.toString())
      }
    }
    .width('100%')
  }

  private formatTime(isoStr: string): string {
    if (!isoStr) return '';
    try {
      const d = new Date(isoStr);
      return `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
    } catch (e) {
      return '';
    }
  }
}
```

---

## 十、路由与配置

### 10.1 在 AppRoutes.ets 中添加路由常量

```typescript
// constants/AppRoutes.ets — 追加一行
static readonly DRIFT_BOTTLE: string = 'pages/DriftBottlePage';
```

### 10.2 在 main_pages.json 中注册页面

```json
// entry/src/main/resources/base/profile/main_pages.json
{
  "src": [
    // ... 已有页面
    "pages/DriftBottlePage"
  ]
}
```

### 10.3 在 module.json5 中添加通知权限

```json5
// entry/src/main/module.json5 — 在 requestPermissions 数组中追加
{
  "name": "ohos.permission.NOTIFICATION_CONTROLLER",
  "reason": "$string:notification_reason",
  "usedScene": {
    "abilities": ["EntryAbility"],
    "when": "always"
  }
}
```

### 10.4 修改 launchType 为 singleton（如需通知跳转）

```json5
// entry/src/main/module.json5 — 修改 EntryAbility
{
  "name": "EntryAbility",
  "launchType": "singleton",   // ← 确保单实例，onNewWant 可接收通知参数
  "srcEntry": "./ets/entryability/EntryAbility.ets"
  // ...
}
```

### 10.5 EntryAbility 中处理通知路由

在 [EntryAbility.ets](entry/src/main/ets/entryability/EntryAbility.ets) 中增加 `onNewWant` 方法：

```typescript
onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  hilog.info(DOMAIN, TAG, 'onNewWant called');
  const targetRoute = want.parameters?.['targetRoute'] as string;
  if (targetRoute) {
    // 通过 AppStorage 传递给 UI 层
    AppStorage.setOrCreate('notify_target_route', targetRoute);
  }
}
```

---

## 十一、后端 API 约定

以下 API 端点需要后端配合实现（供后端开发人员参考）：

| 方法 | 路径 | 请求体 | 响应体 | 说明 |
|------|------|--------|--------|------|
| `POST` | `/api/bottles` | `{memoryId, content, mood}` | `DriftBottle` | 扔出漂流瓶 |
| `GET` | `/api/bottles/random` | — | `DriftBottle` | 随机捞取（排除自己和已捞过的） |
| `POST` | `/api/bottles/:id/resonance` | `{mood}` | `ResonanceLeaf` | 发送共鸣 |
| `GET` | `/api/bottles/mine` | — | `DriftBottle[]` | 我的瓶子列表 |
| `GET` | `/api/bottles/mine/resonances` | — | `ResonanceLeaf[]` | 我收到的共鸣列表 |
| `GET` | `/api/bottles/pickup-count` | — | `{count: number}` | 今日捞取次数 |

**后端核心逻辑**：
- 随机策略：排除当前用户自己的瓶子、已捞取超过 3 次的瓶子、超过 3 天的瓶子
- 每日限制：每人每天最多扔 3 个、捞 3 次（基于 `userId + date` 计数）
- 匿名：捞取时不返回 `authorId`/`authorName`；共鸣通知不暴露回应者身份

---

## 十二、开发步骤（按顺序执行）

1. **创建数据模型**：`DriftBottle.ets` → `ResonanceLeaf.ets`
2. **创建 API 请求体**：在 `ApiRequests.ets` 中追加 `ThrowBottleRequestBody` 和 `SendResonanceRequestBody`
3. **创建服务层**：`DriftRandomEngine.ets` → `DriftBottleNotification.ets`
4. **创建仓库层**：`DriftBottleRepository.ets`
5. **创建 ViewModel**：`DriftBottleViewModel.ets`
6. **创建 Canvas 组件**：`DriftOceanCanvas.ets`
7. **创建 UI 组件**：`ResonanceMoodPicker.ets`
8. **创建页面**：`DriftBottlePage.ets`
9. **配置路由**：更新 `AppRoutes.ets` + `main_pages.json`
10. **配置权限**：更新 `module.json5` + `EntryAbility.ets`
11. **对接后端 API**
12. **测试验证**

---

## 十三、参考资料

| 主题 | 官方文档链接 |
|------|------------|
| Notification Kit 开发指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/notification-overview |
| WantAgent 开发指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wantagent-overview |
| CanvasRenderingContext2D API | https://developer.huawei.com/consumer/cn/doc/harmonyos-references/ts-canvasrenderingcontext2d |
| ArkUI 应用开发总指南 | https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/application-dev-guide |
