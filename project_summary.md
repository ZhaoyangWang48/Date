# 《植忆》项目完整理解备忘录

> 生成时间：2026-07-16
> 用途：PPT 制作与答辩准备的代码理解基础

---

## 一、项目概述

**《植忆》** 是一款面向 HarmonyOS 手机的情感记忆应用，支持用户记录文字、图片、心情和日期，将个人记忆呈现为动态记忆树；同时提供共享树洞、共同一天、时光胶囊、记忆电台和漂流瓶等实验性功能。

**项目架构**：ArkTS 客户端（HarmonyOS） + Spring Boot 服务端（Java） + MySQL/H2 数据库

**开发团队**：项目贡献者

---

## 二、技术栈

### 前端（HarmonyOS）
| 技术项 | 说明 |
|--------|------|
| 语言 | ArkTS |
| UI 框架 | ArkUI 声明式组件 |
| IDE | DevEco Studio |
| SDK | HarmonyOS SDK 26.0.0 Beta1 |
| 设备类型 | Phone（Pura 90 Pro 模拟器） |
| 网络 | @kit.NetworkKit |
| 本地持久化 | @kit.ArkData Preferences |
| AI 语音 | @kit.CoreSpeechKit（TextToSpeech + SpeechRecognizer） |
| 图片选择 | 系统 PhotoPicker |
| 图形绘制 | ArkUI Canvas 2D |
| 通知 | @kit.NotificationKit |
| 服务卡片 | @kit.FormKit |

### 后端（Spring Boot）
| 技术项 | 说明 |
|--------|------|
| 语言 | Java 21 |
| 构建 | Maven |
| 框架 | Spring Boot 3.5.0 |
| 安全 | Spring Security + JWT（JJWT 0.12.6） |
| 数据访问 | Spring Data JPA |
| 数据库迁移 | Flyway |
| 数据库 | MySQL 8（正式）/ H2（演示） |
| API 文档 | Springdoc OpenAPI / Swagger |
| 端口 | 8080 |

---

## 三、前端架构分层

```
entry/src/main/ets/
├── components/          # 可复用 ArkUI 组件和 Canvas
├── constants/           # 接口地址、路由、心情常量
├── models/              # 数据模型（Memory, TimeCapsule, DriftBottle, RadioChannel 等）
├── pages/               # 页面（共 20+ 页面）
├── repositories/        # REST API 映射层
├── services/            # 网络、会话、图片、TTS、通知、本地收藏等
├── viewmodels/          # 页面业务编排和算法（TreeGrowthEngine 等）
├── entryability/        # 应用启动、生命周期管理
├── entryformability/    # 服务卡片生命周期
└── widget/              # 服务卡片 ArkUI 页面
```

**数据流**：Page → ViewModel → Repository → HttpClient → Spring Boot

---

## 四、后端架构分层

```
server/src/main/java/com/zhiyi/server/
├── api/          # Controller、DTO、统一响应、全局异常处理
├── auth/         # JWT 生成、解析、过滤器、UserPrincipal
├── config/       # Security、Web、演示数据初始化
├── domain/       # JPA 实体（10+ 个实体类）
├── repository/   # Spring Data JPA 接口
├── service/      # 核心业务逻辑
├── storage/      # 图片存储、优化、UUID 文件名
└── agent/        # AI 记忆助手（RemembererService）
```

---

## 五、核心功能模块详解

### 5.1 认证与登录
- 注册/登录接口：`POST /api/auth/register` / `POST /api/auth/login`
- 密码 BCrypt 加密，JWT 7 天有效期
- Token 保存到本地 Preferences，自动携带到请求头

### 5.2 个人记忆
- 新增记忆：文字 + 心情 + 单张图片 + 日期/小时
- 图片上传：multipart → 服务端 UUID 文件名 → /uploads/
- 图片预加载：网络 URL 下载到应用沙箱 photo_cache
- 列表/详情/删除/修改完整 CRUD
- 接口：`GET/POST/PATCH/DELETE /api/memories`

### 5.3 记忆树（核心视觉）
- **TreeGrowthEngine**：空间殖民式分支生长算法
  - 用户 ID 作为稳定随机种子
  - 按 createdAt + memoryId 稳定排序
  - 黄金角分布树冠目标
  - 碰撞检测避免叶片重叠
  - 每个节点最多 3 个子分支，22° 最小分叉角
  - 心情映射低饱和叶片颜色
  - 图片记忆使用更大叶片 + 高光
  - 支持叶片命中测试进入详情
- **VineTreeLayout**：轻量螺旋布局（备用）

### 5.4 树洞与共同一天
- 创建树洞、邀请码加入（默认 REMOVED_SECRET）
- 成员权限管理（OWNER / MEMBER）
- 共享记忆发布与查看
- **共同一天**：选择日期 + 小时，时间轴展示该时刻多人记忆
- 一键导出拼图 collage 保存到相册
- AI 记忆守护者：基于树洞记忆做语义检索（Embedding）并回答

### 5.5 时光胶囊（新功能1）
- **核心流程**：输入文字 → 选择心情 → 设定开启时间 → 封存 → 到期通知 → 开启动画 → AI 朗读
- **开启时间选项**：1分钟（测试）/ 1周 / 1月 / 3月 / 1年
- **AI 语音输入**：Core Speech Kit SpeechRecognizer，最长 60 秒，追加到文本
- **AI 朗读**：CapsuleTtsService 封装 textToSpeech，自动探测中文音色，在线/离线回退
- **开花动画**：CapsuleBloomCanvas，42 帧渐变绽放，径向渐变 + 贝塞尔花瓣 + 粒子散射
- **到期提醒**：前台每秒轮询检查，NotificationKit 发布系统通知
- **状态流转**：未到期 → 已到期未开启 → 已开启（服务端 Clock 校验防篡改）
- **时间精度**：openAt 使用 LocalDateTime，Flyway V4 迁移升级

### 5.6 记忆电台（新功能2）
- **四大频道**：时光倒流 / 阳光电台 / 影像馆 / 深夜树洞
- **频道主题**：每个频道独立 RadioTheme（背景渐变、卡片色、强调色）
- **TTS 播报**：复用 CapsuleTtsService，统一默认音色
- **收藏机制**：RadioPlaylistStore 使用 Preferences 本地持久化
- **播放控制**：开始/停止/下一段，TtsPlaybackState 状态管理

### 5.7 漂流瓶（新功能3）
- **三大标签**：扔出 / 捞起 / 我的共鸣
- **匿名机制**：不返回作者身份
- **次数限制**：每日最多扔 3 个、捞 3 次
- **共鸣机制**：感动/同感/祝福/温暖/想念，只能共鸣一次，不能自共鸣
- **过期机制**：3 天后过期沉入海底
- **Canvas 海面**：DriftOceanCanvas，多层正弦波浪 + 气泡粒子 + 漂流瓶浮动

### 5.8 桌面服务卡片（Form Kit）
- **Widget**：RecentPhotoWidget，2×2 网格展示最近 4 张照片
- **数据同步**：WidgetPhotoCache 双缓存（同步 JSON 文件 + 异步 Preferences）
- **图片预下载**：ImagePreloader 下载到沙箱，通过 fd 传递给卡片
- **生命周期**：onAddForm → onUpdateForm → onChangeFormVisibility → onRemoveForm
- **点击跳转**：postCardAction 路由直达应用首页

### 5.9 AI 图片解读（大模型）
- **流程**：拍照 → 上传 → 点击"大模型帮我写" → 后端调用多模态大模型 → 返回草稿
- **后端接口**：`POST /api/memory-draft`，JWT 认证，超时 95 秒
- **安全设计**：AI 密钥仅存服务端环境变量，不写入客户端
- **降级处理**：模型不可用返回友好提示，不影响主发布流程

### 5.10 AI 记忆守护者（树洞）
- **接口**：`POST /api/agent/rememberer/chat`
- **实现**：RemembererService，先语义检索（Embedding API）再 Chat Completion
- **返回**：温暖简短中文回答 + 引用记忆来源列表

---

## 六、数据库设计（Flyway 迁移）

| 表名 | 用途 | 创建版本 |
|------|------|----------|
| users | 用户账户 | V1 |
| tree_holes | 树洞 | V1 |
| tree_members | 树洞成员关系 | V1 |
| memories | 记忆（个人+共享） | V1 |
| memory_embeddings | 记忆向量嵌入 | V2 |
| time_capsules | 时光胶囊 | V3 |
| drift_bottles | 漂流瓶 | V3 |
| bottle_pickups | 漂流瓶拾取记录 | V3 |
| bottle_resonances | 漂流瓶共鸣记录 | V3 |
| recall_cards | 回忆卡片 | - |

---

## 七、HarmonyOS 系统能力使用点

| 能力 | 使用场景 | 对应文件 |
|------|----------|----------|
| Core Speech Kit - TextToSpeech | 时光胶囊朗读、记忆电台播报 | CapsuleTtsService.ets |
| Core Speech Kit - SpeechRecognizer | 时光胶囊语音输入 | SpeechInputService.ets |
| Canvas 2D | 记忆树绘制、开花动画、海面背景 | VineTreeCanvas.ets, CapsuleBloomCanvas.ets, DriftOceanCanvas.ets |
| Form Kit | 桌面服务卡片 | EntryFormAbility.ets, RecentPhotoWidget.ets |
| Notification Kit | 胶囊到期提醒 | CapsuleReminderService.ets |
| Network Kit | HTTP 网络请求 | HttpClient.ets |
| ArkData Preferences | 本地持久化（Token、收藏、卡片缓存） | TokenStorage.ets, RadioPlaylistStore.ets, WidgetPhotoCache.ets |
| PhotoPicker | 图片选择 | ImagePickerService.ets |
| Stage 模型生命周期 | 前后台资源管理 | EntryAbility.ets |

---

## 八、PPT 现有状态

**已存在文件**：
- `ppt_defense/defense.pptd` — PPT 定义文件（13页）
- `ppt_defense/pages/` — 13 个 .page 页面文件
- `ppt_defense/outline.md` — 答辩大纲
- `ppt_defense/design.md` — 设计规范（BJUT 风格，蓝橙配色）
- `植忆APP功能答辩.pptx` — 已生成的 PPT 文件

**PPT 结构（13页）**：
1. 封面
2. 目录（5大功能）
3. 时间胶囊 — 功能概述
4. 时间胶囊 — 鸿蒙AI特性与动画
5. 记忆电台 — 功能概述
6. 记忆电台 — AI语音播报实现
7. 漂流瓶 — 功能概述
8. 漂流瓶 — Canvas动态海面绘制
9. 桌面服务卡片 — Form Kit卡片功能
10. 桌面服务卡片 — 图片缓存与生命周期
11. AI图片解读 — 功能概述
12. AI图片解读 — 大模型调用流程
13. 总结

**设计风格**：
- 尺寸：1280 × 720（16:9）
- 主色：#0066A2（工大蓝）
- 辅色：#4A90B8（浅蓝）
- 强调色：#D97706（暖橙）
- 字体：MiSans
- 布局：标题栏 + 内容区 + 底部注释区

---

## 九、关键代码文件清单

### 前端核心文件（ETS）
| 类别 | 文件路径 |
|------|----------|
| 入口 | entryability/EntryAbility.ets |
| 主页面 | pages/MainTabPage.ets, pages/HomePage.ets |
| 登录 | pages/LoginPage.ets, pages/RegisterPage.ets |
| 记忆 | pages/AddMemoryPage.ets, pages/MemoryListPage.ets, pages/MemoryDetailPage.ets, pages/MemoryTreePage.ets |
| 树洞 | pages/SharedTreePage.ets, pages/CommonDayPage.ets |
| 时光胶囊 | pages/TimeCapsuleGardenPage.ets, pages/CapsuleOpenPage.ets |
| 记忆电台 | pages/MemoryRadioPage.ets |
| 漂流瓶 | pages/DriftBottlePage.ets |
| 记忆树算法 | viewmodels/TreeGrowthEngine.ets, viewmodels/VineTreeLayout.ets |
| TTS 服务 | services/CapsuleTtsService.ets |
| 语音输入 | services/SpeechInputService.ets, components/VoiceInputButton.ets |
| 提醒服务 | services/CapsuleReminderService.ets |
| 动画组件 | components/CapsuleBloomCanvas.ets, components/DriftOceanCanvas.ets, components/VineTreeCanvas.ets |
| 服务卡片 | widget/pages/RecentPhotoWidget.ets, entryformability/EntryFormAbility.ets |
| 网络 | services/HttpClient.ets, constants/ApiConfig.ets |
| 存储 | services/TokenStorage.ets, services/WidgetPhotoCache.ets, services/RadioPlaylistStore.ets |

### 后端核心文件（Java）
| 类别 | 文件路径 |
|------|----------|
| 入口 | ZhiyiServerApplication.java |
| 认证 | api/AuthController.java, auth/JwtService.java, auth/JwtAuthenticationFilter.java, service/AuthService.java |
| 记忆 | api/MemoryController.java, service/MemoryService.java, domain/MemoryEntity.java |
| 树洞 | api/TreeHoleController.java, service/TreeHoleService.java |
| 时光胶囊 | api/TimeCapsuleController.java, service/TimeCapsuleService.java, domain/TimeCapsuleEntity.java |
| 漂流瓶 | api/DriftBottleController.java, service/DriftBottleService.java, domain/DriftBottleEntity.java |
| AI 助手 | agent/AgentController.java, agent/RemembererService.java |
| AI 草稿 | api/MemoryDraftController.java, agent/MemoryDraftService.java |
| 配置 | config/SecurityConfig.java, config/DemoDataInitializer.java |
| 存储 | storage/FileStorageService.java, storage/ImageOptimizationService.java |
| DTO | api/Dtos.java, api/ApiResponse.java |

---

## 十、测试状态

- **后端**：`mvn test` 6 测试全部通过，覆盖注册、登录、记忆、图片上传、时光胶囊、漂流瓶
- **前端**：HAP 构建成功，记忆电台四频道主题已接入，语音输入待真机验收

---

## 十一、安全设计

- 密码 BCrypt 加密
- JWT 7 天有效期，无状态会话
- AI 密钥仅存服务端环境变量
- 漂流瓶匿名响应不泄露作者身份
- 时光胶囊开启时间服务端校验（Clock 注入）
- 图片上传大小限制（2MB）

---

*本备忘录基于对项目代码的完整阅读，涵盖 docs/PROJECT_HANDOFF_2026-07-14.md、artifact.md、全部 ETS 源码、全部 Java 源码、数据库迁移脚本和 PPT 相关文件。*
