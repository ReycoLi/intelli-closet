# Intelli-Closet MVP 设计文档

## 概述

Intelli-Closet 是一款 iOS App，帮助用户通过 AI 管理衣橱并获取智能穿搭推荐，解决每日选衣的选择困难症。

## 架构决策

- **纯 iOS 客户端**：Swift/SwiftUI，直接调用阿里云百炼 API，无后端服务器
- **本地存储**：SwiftData 持久化衣物数据和用户信息
- **AI 服务**：阿里云百炼（Qwen VL 图片理解、Qwen 3.5-plus 文本/多模态推荐）
- **天气服务**：Apple WeatherKit

## 导航结构

Tab Bar 四个标签页：

1. **衣橱** — 浏览所有衣物，按类别/属性筛选
2. **添加** — 拍照/相册 → AI 分析 → 确认保存
3. **推荐** — 选择场合 → 获取智能搭配推荐
4. **我的** — 用户信息（身高、体重、照片）、设置

## 数据模型

### ClothingItem（衣物）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | UUID | 唯一标识 |
| name | String | AI 生成的独特名称，如"雾蓝亚麻衬衫" |
| photo | Data | 原始照片 |
| thumbnail | Data | 缩略图（列表用） |
| category | enum | .top / .bottom |
| subcategory | String | 衬衫、T恤、卫衣、西裤、牛仔裤等 |
| primaryColor | String | 主色 |
| secondaryColor | String? | 辅色（可选） |
| material | String | 材质 |
| warmthLevel | Int | 保暖等级 1-5（1=轻薄，5=厚实） |
| styleTags | [String] | 风格标签：休闲、通勤、街头、正式等 |
| fit | String | 版型：宽松、修身、常规 |
| description | String | AI 生成的自然语言描述（质感、细节、搭配方向） |
| createdAt | Date | 创建时间 |

### UserProfile（用户信息）

| 字段 | 类型 | 说明 |
|------|------|------|
| height | Double? | 身高 cm |
| weight | Double? | 体重 kg |
| headshotPhoto | Data? | 大头照 |
| fullBodyPhoto | Data? | 全身照 |

### OutfitRecommendation（推荐结果，内存模型，不持久化）

| 字段 | 类型 | 说明 |
|------|------|------|
| top | ClothingItem | 上装 |
| bottom | ClothingItem | 下装 |
| reasoning | String | 推荐理由 |

设计要点：
- 照片直接存 SwiftData（Data 类型），MVP 单用户无需文件系统管理
- warmthLevel 用 1-5 整数而非季节标签，便于和天气温度匹配
- styleTags 为数组，一件衣服可同时具有多个风格标签
- 推荐结果不持久化，MVP 不需要历史记录

## 核心流程

### 流程 1：衣物拍照上传

1. 用户拍照或从相册选择照片
2. 显示照片预览，确认上传
3. 进度视图："正在分析衣物..."
4. 调用 Qwen VL（一次调用完成质量检测 + 属性提取 + 名称生成 + 自然语言描述）
   - 照片质量不合格 → 提示用户重拍，说明原因（模糊/不完整/背景杂乱）
   - 合格 → 返回结构化属性 + 名称 + 描述
5. 展示分析结果，用户可编辑任何字段
6. 确认保存 → 写入 SwiftData

### 流程 2：衣物浏览与编辑

1. 衣橱 Tab 默认按类别分组显示（上装/下装）
2. 支持筛选：类别、风格、颜色、保暖等级
3. 点击衣物 → 详情页（大图 + 所有属性）
4. 编辑模式 → 修改任意字段
5. 支持删除衣物

### 流程 3：智能推荐（两阶段）

用户操作：
1. 选择出门目的（预设：上班/逛街/参加 party/遛狗等 + 自定义输入）
2. 选择推荐套数（1-3，默认 2）
3. 点击"开始推荐"

推荐过程（全程进度可见）：

**Step 1 — 获取天气**
- WeatherKit 基于定位获取
- 降级：定位失败 → 用户手动输入城市 → 再失败 → 用户直接描述天气

**Step 2 — 本地预筛选**
- 根据温度排除保暖等级不匹配的衣物
- 根据场合/风格标签粗筛
- 显示"已从 X 件中筛出 Y 件候选"

**Step 3 — 文本粗选（Qwen 3.5-plus，纯文本）**
- 发送候选衣物的元数据（标签 + 自然语言描述）
- 返回 6-8 件入围单品

**Step 4 — 多模态精选（Qwen 3.5-plus，图文混合，streaming）**
- 发送入围衣物的实际照片 + 元数据
- LLM 基于真实图片做最终审美判断（颜色搭配、质感协调、风格统一）
- 返回最终 2-3 套搭配 + 推荐理由（streaming 逐字展示）

结果展示：
- 每套搭配以拼图形式展示（上装 + 下装）
- 下方显示推荐理由
- 左右滑动切换不同方案

## Service Layer

### AliyunService

统一封装所有阿里云百炼 API 调用，通过 OpenAI 兼容接口（`https://dashscope.aliyuncs.com/compatible-mode/v1`）。

- **analyzeClothing(image: Data) → ClothingAnalysisResult**
  - 模型：Qwen VL 系列
  - 一次调用：质量检测 + 属性提取 + 名称生成 + 自然语言描述
  - 返回结构化 JSON

- **textSelectOutfits(candidates, occasion, weather) → [String]**
  - 模型：Qwen 3.5-plus（纯文本）
  - 输入：候选衣物元数据 + 场合 + 天气
  - 返回：入围衣物 ID 列表

- **multimodalRecommend(items, occasion, weather, count) → [OutfitRecommendation]**
  - 模型：Qwen 3.5-plus（图文混合，streaming）
  - 输入：6-8 件衣物照片 + 元数据 + 场合 + 天气
  - 返回：最终搭配方案 + 推荐理由

### WeatherService

- **fetchWeather(location: CLLocation) → WeatherInfo**
  - Apple WeatherKit
  - 返回：温度、体感温度、天气状况、湿度、风力
- 降级链：WeatherKit → 用户输入城市查询 → 用户直接描述天气

### LocalFilterService

- **filterCandidates(allItems, weather, occasion) → [ClothingItem]**
  - 纯本地逻辑，不调 API
  - 温度 → 保暖等级匹配（如 >28°C 排除 warmthLevel >= 4）
  - 场合 → 风格标签匹配

## 错误处理

- API 调用失败 → 显示错误提示 + 重试按钮
- 照片质量不合格 → 明确告知原因 + 引导重拍
- 网络不可用 → 衣橱浏览正常（本地数据），推荐功能提示需要网络

## 未来扩展（MVP 不实现）

- AI 试穿预览（qwen-image 生图）
- 鞋帽首饰等更多品类
- 用户偏好学习
- 推荐历史记录
- 评估反馈系统
