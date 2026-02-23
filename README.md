# Intelli Closet 智能衣橱

一款基于 AI 的 iOS 智能衣橱管理与穿搭推荐 App。拍照或从相册导入衣物，AI 自动识别属性，根据天气和场合智能推荐搭配方案。

## 功能

### 衣物管理
- 拍照添加单件衣物，AI 自动识别名称、分类、颜色、材质、保暖等级、风格标签等
- 批量导入（最多 5 张），并行 AI 分析，逐件审核编辑后保存
- 基于缩略图哈希的重复检测，避免重复添加
- 衣橱网格浏览，支持查看详情和编辑

### 智能推荐
- 选择场合（上班、逛街、约会等），自动获取当前天气
- 本地预筛选：根据温度过滤保暖等级，根据场合过滤风格标签
- 筛选透明化：展示过滤逻辑和每件衣物被过滤的具体原因
- AI 多模态推荐：基于衣物照片进行视觉搭配分析
- 结构化推荐理由：颜色搭配、风格协调、天气适配、场合匹配、整体美感
- 流式生成，实时展示推荐进度

### 用户体验
- 保暖等级可视化：轻薄/透气/适中/保暖/厚实，附温度范围和典型衣物示例
- 批量审核支持左右滑动切换，逐件保存或跳过
- 推荐过程中展示动态提示动画

## 技术栈

- Swift 6 / SwiftUI
- SwiftData（本地持久化）
- 阿里云百炼 DashScope API（通义千问 qwen-vl-max / qwen3.5-plus）
- Open-Meteo API（天气数据）
- CryptoKit（SHA256 图片去重）
- CoreLocation（定位）

## 项目结构

```
intelli-closet/
├── Models/              # 数据模型
│   ├── ClothingItem.swift
│   ├── ClothingCategory.swift
│   ├── ClothingAnalysisResult.swift
│   ├── OutfitRecommendation.swift
│   ├── UserProfile.swift
│   ├── WarmthLevel.swift
│   └── WeatherInfo.swift
├── Services/            # 服务层
│   ├── AliyunService.swift       # AI 分析与推荐
│   ├── LocalFilterService.swift  # 本地筛选
│   └── WeatherService.swift      # 天气获取
├── ViewModels/          # 视图模型
│   ├── AddClothingViewModel.swift
│   ├── ProfileViewModel.swift
│   └── RecommendViewModel.swift
├── Views/
│   ├── AddClothing/     # 添加衣物流程
│   ├── Recommend/       # 智能推荐流程
│   ├── Wardrobe/        # 衣橱浏览
│   ├── Profile/         # 用户资料
│   └── MainTabView.swift
└── Utilities/
    └── ImageUtils.swift
```

## 环境要求

- Xcode 16+
- iOS 18+
- 阿里云百炼 API Key（已内置于 AliyunService 中，发布前请替换为自己的 Key）

## 运行

1. 克隆项目
2. 用 Xcode 打开 `intelli-closet.xcodeproj`
3. 选择真机或模拟器，Build & Run

## License

MIT
