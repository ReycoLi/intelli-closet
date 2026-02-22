# Intelli-Closet MVP Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a complete iOS MVP that lets users photograph clothing, get AI-powered attribute analysis, browse their wardrobe, and receive smart outfit recommendations.

**Architecture:** Pure iOS client (Swift/SwiftUI) with direct API calls to Aliyun Bailian (OpenAI-compatible endpoint). Local persistence via SwiftData. Weather via Apple WeatherKit.

**Tech Stack:** Swift 6, SwiftUI, SwiftData, WeatherKit, Aliyun Bailian (Qwen VL, Qwen 3.5-plus), URLSession for HTTP

---

### Task 1: Project Structure & SwiftData Models

**Files:**
- Create: `intelli-closet/Models/ClothingItem.swift`
- Create: `intelli-closet/Models/UserProfile.swift`
- Create: `intelli-closet/Models/ClothingCategory.swift`
- Modify: `intelli-closet/intelli_closetApp.swift`

**Step 1: Create ClothingCategory enum**

```swift
// intelli-closet/Models/ClothingCategory.swift
import Foundation

enum ClothingCategory: String, Codable, CaseIterable {
    case top = "上装"
    case bottom = "下装"
}
```

**Step 2: Create ClothingItem model**

```swift
// intelli-closet/Models/ClothingItem.swift
import Foundation
import SwiftData

@Model
class ClothingItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var photo: Data
    @Attribute(.externalStorage) var thumbnail: Data
    var categoryRaw: String
    var subcategory: String
    var primaryColor: String
    var secondaryColor: String?
    var material: String
    var warmthLevel: Int
    var styleTags: [String]
    var fit: String
    var itemDescription: String
    var createdAt: Date

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .top }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        name: String,
        photo: Data,
        thumbnail: Data,
        category: ClothingCategory,
        subcategory: String,
        primaryColor: String,
        secondaryColor: String? = nil,
        material: String,
        warmthLevel: Int,
        styleTags: [String],
        fit: String,
        itemDescription: String
    ) {
        self.id = UUID()
        self.name = name
        self.photo = photo
        self.thumbnail = thumbnail
        self.categoryRaw = category.rawValue
        self.subcategory = subcategory
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.material = material
        self.warmthLevel = warmthLevel
        self.styleTags = styleTags
        self.fit = fit
        self.itemDescription = itemDescription
        self.createdAt = Date()
    }
}
```
**Step 3: Create UserProfile model**

```swift
// intelli-closet/Models/UserProfile.swift
import Foundation
import SwiftData

@Model
class UserProfile {
    var id: UUID
    var height: Double?
    var weight: Double?
    @Attribute(.externalStorage) var headshotPhoto: Data?
    @Attribute(.externalStorage) var fullBodyPhoto: Data?

    init(height: Double? = nil, weight: Double? = nil) {
        self.id = UUID()
        self.height = height
        self.weight = weight
    }
}
```

**Step 4: Register models in App entry point**

```swift
// intelli-closet/intelli_closetApp.swift
import SwiftUI
import SwiftData

@main
struct intelli_closetApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [ClothingItem.self, UserProfile.self])
    }
}
```

**Step 5: Commit**

```bash
git add intelli-closet/Models/ intelli-closet/intelli_closetApp.swift
git commit -m "feat: add SwiftData models for ClothingItem and UserProfile"
```

---
### Task 2: Tab Bar Navigation Shell

**Files:**
- Create: `intelli-closet/Views/MainTabView.swift`
- Create: `intelli-closet/Views/Wardrobe/WardrobeView.swift`
- Create: `intelli-closet/Views/AddClothing/AddClothingView.swift`
- Create: `intelli-closet/Views/Recommend/RecommendView.swift`
- Create: `intelli-closet/Views/Profile/ProfileView.swift`
- Delete: `intelli-closet/ContentView.swift`

**Step 1: Create MainTabView**

```swift
// intelli-closet/Views/MainTabView.swift
import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Label("衣橱", systemImage: "tshirt")
                }
            AddClothingView()
                .tabItem {
                    Label("添加", systemImage: "camera")
                }
            RecommendView()
                .tabItem {
                    Label("推荐", systemImage: "sparkles")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .tint(.mint)
    }
}
```

**Step 2: Create placeholder views for each tab**

```swift
// intelli-closet/Views/Wardrobe/WardrobeView.swift
import SwiftUI

struct WardrobeView: View {
    var body: some View {
        NavigationStack {
            Text("衣橱")
                .navigationTitle("我的衣橱")
        }
    }
}
```

```swift
// intelli-closet/Views/AddClothing/AddClothingView.swift
import SwiftUI

struct AddClothingView: View {
    var body: some View {
        NavigationStack {
            Text("添加衣物")
                .navigationTitle("添加衣物")
        }
    }
}
```

```swift
// intelli-closet/Views/Recommend/RecommendView.swift
import SwiftUI

struct RecommendView: View {
    var body: some View {
        NavigationStack {
            Text("智能推荐")
                .navigationTitle("智能推荐")
        }
    }
}
```

```swift
// intelli-closet/Views/Profile/ProfileView.swift
import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            Text("个人信息")
                .navigationTitle("我的")
        }
    }
}
```

**Step 3: Delete ContentView.swift**

Remove the old placeholder file.

**Step 4: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED, app shows tab bar with 4 tabs.

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add tab bar navigation with placeholder views"
```

---
### Task 3: Aliyun API Service Layer

**Files:**
- Create: `intelli-closet/Services/AliyunService.swift`
- Create: `intelli-closet/Models/ClothingAnalysisResult.swift`
- Create: `intelli-closet/Models/OutfitRecommendation.swift`

**Step 1: Create ClothingAnalysisResult model**

```swift
// intelli-closet/Models/ClothingAnalysisResult.swift
import Foundation

struct ClothingAnalysisResult: Codable {
    let isValid: Bool
    let invalidReason: String?
    let name: String?
    let category: String?
    let subcategory: String?
    let primaryColor: String?
    let secondaryColor: String?
    let material: String?
    let warmthLevel: Int?
    let styleTags: [String]?
    let fit: String?
    let description: String?
}
```

**Step 2: Create OutfitRecommendation model**

```swift
// intelli-closet/Models/OutfitRecommendation.swift
import Foundation

struct OutfitRecommendation: Identifiable {
    let id = UUID()
    let top: ClothingItem
    let bottom: ClothingItem
    let reasoning: String
}
```

**Step 3: Create AliyunService with clothing analysis**

```swift
// intelli-closet/Services/AliyunService.swift
import Foundation

actor AliyunService {
    static let shared = AliyunService()

    private let apiKey = "sk-d786ca6e288a4e6aa977de07d479a3a8"
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"

    // MARK: - Clothing Analysis (Qwen VL)

    func analyzeClothing(imageData: Data) async throws -> ClothingAnalysisResult {
        let base64Image = imageData.base64EncodedString()
        let messages: [[String: Any]] = [
            ["role": "system", "content": "你是一个专业的服装分析助手。"],
            ["role": "user", "content": [
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64Image)"]],
                ["type": "text", "text": """
                请分析这张衣物照片。

                首先判断照片质量：如果照片模糊、不完整、背景过于杂乱无法识别衣物，返回 isValid=false 并说明原因。

                如果照片合格，请识别以下属性并以JSON格式返回：
                {
                    "isValid": true,
                    "name": "给这件衣物起一个独特有美感的中文名称",
                    "category": "上装 或 下装",
                    "subcategory": "具体类别如衬衫/T恤/卫衣/西裤/牛仔裤等",
                    "primaryColor": "主色",
                    "secondaryColor": "辅色（没有则为null）",
                    "material": "材质",
                    "warmthLevel": 1到5的整数（1=轻薄 5=厚实保暖）,
                    "styleTags": ["风格标签数组，如休闲/通勤/街头/正式"],
                    "fit": "版型：宽松/修身/常规",
                    "description": "一段自然语言描述，包含面料质感、图案细节、视觉印象、适合搭配的方向"
                }

                如果照片不合格：
                {"isValid": false, "invalidReason": "具体原因"}

                只返回JSON，不要其他内容。
                """]
            ]]
        ]

        let body: [String: Any] = [
            "model": "qwen-vl-max",
            "messages": messages,
            "temperature": 0.3
        ]

        let data = try await makeRequest(body: body)
        let content = try extractContent(from: data)
        let jsonData = content.data(using: .utf8)!
        return try JSONDecoder().decode(ClothingAnalysisResult.self, from: jsonData)
    }

    // MARK: - Private Helpers

    private func makeRequest(body: [String: Any], stream: Bool = false) async throws -> Data {
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw AliyunError.requestFailed
        }
        return data
    }

    private func extractContent(from data: Data) throws -> String {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AliyunError.invalidResponse
        }
        return content
    }
}

enum AliyunError: LocalizedError {
    case requestFailed
    case invalidResponse
    case streamingFailed

    var errorDescription: String? {
        switch self {
        case .requestFailed: return "API 请求失败，请检查网络连接"
        case .invalidResponse: return "API 返回格式异常"
        case .streamingFailed: return "流式响应中断"
        }
    }
}
```

**Step 4: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add intelli-closet/Services/ intelli-closet/Models/
git commit -m "feat: add AliyunService with clothing analysis API"
```

---
### Task 4: Add Recommendation Methods to AliyunService

**Files:**
- Modify: `intelli-closet/Services/AliyunService.swift`
- Create: `intelli-closet/Models/WeatherInfo.swift`

**Step 1: Create WeatherInfo model**

```swift
// intelli-closet/Models/WeatherInfo.swift
import Foundation

struct WeatherInfo {
    let temperature: Double
    let feelsLike: Double
    let condition: String
    let humidity: Double
    let windSpeed: Double

    var summary: String {
        "温度\(Int(temperature))°C（体感\(Int(feelsLike))°C），\(condition)，湿度\(Int(humidity * 100))%，风速\(Int(windSpeed))km/h"
    }
}
```

**Step 2: Add textSelectOutfits to AliyunService**

Add this method to `AliyunService`:

```swift
// MARK: - Text-based Outfit Selection (Stage 1)

func textSelectOutfits(
    candidates: [ClothingItem],
    occasion: String,
    weather: WeatherInfo
) async throws -> [UUID] {
    let clothingList = candidates.map { item in
        """
        [ID: \(item.id.uuidString)]
        名称: \(item.name)
        类别: \(item.categoryRaw) - \(item.subcategory)
        主色: \(item.primaryColor)\(item.secondaryColor.map { "，辅色: \($0)" } ?? "")
        材质: \(item.material) | 保暖等级: \(item.warmthLevel)/5
        风格: \(item.styleTags.joined(separator: "、")) | 版型: \(item.fit)
        描述: \(item.itemDescription)
        """
    }.joined(separator: "\n---\n")

    let messages: [[String: Any]] = [
        ["role": "system", "content": "你是一个专业的穿搭顾问，擅长根据场合和天气推荐合适的服装搭配。"],
        ["role": "user", "content": """
        以下是我衣橱中的候选衣物：

        \(clothingList)

        今天的场合：\(occasion)
        天气情况：\(weather.summary)

        请从中挑选6-8件最适合的单品（上装和下装都要有），用于后续搭配。
        考虑因素：场合适配、天气适配、颜色和风格的搭配潜力。

        只返回选中衣物的ID列表，JSON格式：
        {"selectedIds": ["id1", "id2", ...]}
        """]
    ]

    let body: [String: Any] = [
        "model": "qwen3.5-plus",
        "messages": messages,
        "temperature": 0.5
    ]

    let data = try await makeRequest(body: body)
    let content = try extractContent(from: data)
    let jsonData = content.data(using: .utf8)!
    let result = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
    let ids = result?["selectedIds"] as? [String] ?? []
    return ids.compactMap { UUID(uuidString: $0) }
}
```

**Step 3: Add multimodalRecommend with streaming to AliyunService**

```swift
// MARK: - Multimodal Recommendation (Stage 2, Streaming)

func multimodalRecommend(
    items: [ClothingItem],
    occasion: String,
    weather: WeatherInfo,
    count: Int
) -> AsyncThrowingStream<String, Error> {
    AsyncThrowingStream { continuation in
        Task {
            do {
                var contentParts: [[String: Any]] = []

                for item in items {
                    let base64 = item.photo.base64EncodedString()
                    contentParts.append([
                        "type": "image_url",
                        "image_url": ["url": "data:image/jpeg;base64,\(base64)"]
                    ])
                    contentParts.append([
                        "type": "text",
                        "text": "[\(item.id.uuidString)] \(item.name)（\(item.categoryRaw)，\(item.primaryColor)，\(item.styleTags.joined(separator: "/"))）"
                    ])
                }

                contentParts.append([
                    "type": "text",
                    "text": """
                    以上是候选衣物的照片和信息。

                    场合：\(occasion)
                    天气：\(weather.summary)

                    请根据照片中衣物的实际颜色、质感、风格，推荐\(count)套搭配方案。
                    每套包含一件上装和一件下装。

                    重点考虑：
                    1. 颜色搭配是否和谐
                    2. 质感和风格是否统一
                    3. 是否适合场合和天气
                    4. 整体审美感

                    返回JSON格式：
                    {"outfits": [{"topId": "id", "bottomId": "id", "reasoning": "简短推荐理由"}]}
                    """
                ])

                let messages: [[String: Any]] = [
                    ["role": "system", "content": "你是一个有审美品味的穿搭顾问。基于衣物的实际照片做出搭配判断。"],
                    ["role": "user", "content": contentParts]
                ]

                let body: [String: Any] = [
                    "model": "qwen3.5-plus",
                    "messages": messages,
                    "temperature": 0.7,
                    "stream": true
                ]

                let url = URL(string: "\(baseURL)/chat/completions")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONSerialization.data(withJSONObject: body)

                let (bytes, response) = try await URLSession.shared.bytes(for: request)
                guard let httpResponse = response as? HTTPURLResponse,
                      200..<300 ~= httpResponse.statusCode else {
                    throw AliyunError.requestFailed
                }

                for try await line in bytes.lines {
                    guard line.hasPrefix("data: ") else { continue }
                    let jsonStr = String(line.dropFirst(6))
                    if jsonStr == "[DONE]" { break }
                    guard let lineData = jsonStr.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                          let choices = json["choices"] as? [[String: Any]],
                          let delta = choices.first?["delta"] as? [String: Any],
                          let content = delta["content"] as? String else { continue }
                    continuation.yield(content)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}
```

**Step 4: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 5: Commit**

```bash
git add -A
git commit -m "feat: add text selection and multimodal recommendation to AliyunService"
```

---
### Task 5: Weather & Location Services

**Files:**
- Create: `intelli-closet/Services/WeatherService.swift`

**Step 1: Create WeatherService**

```swift
// intelli-closet/Services/WeatherService.swift
import Foundation
import CoreLocation
import WeatherKit

@Observable
class WeatherService: NSObject, CLLocationManagerDelegate {
    static let shared = WeatherService()

    private let locationManager = CLLocationManager()
    private let weatherService = WeatherKit.WeatherService.shared
    private var locationContinuation: CheckedContinuation<CLLocation, Error>?

    var lastWeather: WeatherInfo?
    var locationError: Error?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public

    func fetchWeather() async throws -> WeatherInfo {
        let location = try await requestLocation()
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        let info = WeatherInfo(
            temperature: current.temperature.value,
            feelsLike: current.apparentTemperature.value,
            condition: current.condition.description,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value
        )
        lastWeather = info
        return info
    }

    func fetchWeatherByCity(_ city: String) async throws -> WeatherInfo {
        let geocoder = CLGeocoder()
        let placemarks = try await geocoder.geocodeAddressString(city)
        guard let location = placemarks.first?.location else {
            throw WeatherError.cityNotFound
        }
        let weather = try await weatherService.weather(for: location)
        let current = weather.currentWeather

        let info = WeatherInfo(
            temperature: current.temperature.value,
            feelsLike: current.apparentTemperature.value,
            condition: current.condition.description,
            humidity: current.humidity,
            windSpeed: current.wind.speed.value
        )
        lastWeather = info
        return info
    }

    // MARK: - Location

    private func requestLocation() async throws -> CLLocation {
        locationManager.requestWhenInUseAuthorization()
        return try await withCheckedThrowingContinuation { continuation in
            self.locationContinuation = continuation
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationContinuation?.resume(returning: location)
            locationContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: error)
        locationContinuation = nil
    }
}

enum WeatherError: LocalizedError {
    case cityNotFound
    case locationDenied

    var errorDescription: String? {
        switch self {
        case .cityNotFound: return "未找到该城市"
        case .locationDenied: return "定位权限被拒绝"
        }
    }
}
```

**Step 2: Add location permission to Info.plist**

Add `NSLocationWhenInUseUsageDescription` with value `"需要获取您的位置以查询当地天气，为您推荐合适的穿搭"` to the Xcode project's Info.plist or target settings.

**Step 3: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add WeatherService with location and city-based weather"
```

---
### Task 6: Local Filter Service

**Files:**
- Create: `intelli-closet/Services/LocalFilterService.swift`

**Step 1: Create LocalFilterService**

```swift
// intelli-closet/Services/LocalFilterService.swift
import Foundation

struct LocalFilterService {

    /// Maps occasion keywords to relevant style tags
    private static let occasionStyleMap: [String: [String]] = [
        "上班": ["通勤", "正式"],
        "逛街": ["休闲", "街头"],
        "参加party": ["正式", "休闲"],
        "遛狗": ["休闲", "街头"],
        "约会": ["休闲", "通勤"],
        "运动": ["休闲", "街头"]
    ]

    /// Filter candidates based on weather and occasion
    static func filterCandidates(
        allItems: [ClothingItem],
        weather: WeatherInfo,
        occasion: String
    ) -> [ClothingItem] {
        let temp = weather.temperature

        // Step 1: Filter by warmth level based on temperature
        let warmthFiltered = allItems.filter { item in
            switch temp {
            case ..<10:  return item.warmthLevel >= 3  // cold: need warm clothes
            case 10..<20: return item.warmthLevel >= 2 && item.warmthLevel <= 4
            case 20..<28: return item.warmthLevel <= 3
            default:      return item.warmthLevel <= 2  // hot: light clothes only
            }
        }

        // Step 2: Prefer matching styles for the occasion, but don't exclude if no match
        let relevantStyles = occasionStyleMap[occasion] ?? []
        if relevantStyles.isEmpty {
            return warmthFiltered
        }

        let styleMatched = warmthFiltered.filter { item in
            !Set(item.styleTags).isDisjoint(with: Set(relevantStyles))
        }

        // If style filtering is too aggressive (< 6 items), fall back to warmth-only
        return styleMatched.count >= 6 ? styleMatched : warmthFiltered
    }
}
```

**Step 2: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add intelli-closet/Services/LocalFilterService.swift
git commit -m "feat: add LocalFilterService for weather and occasion filtering"
```

---
### Task 7: Image Utilities

**Files:**
- Create: `intelli-closet/Utilities/ImageUtils.swift`

**Step 1: Create image compression and thumbnail utilities**

```swift
// intelli-closet/Utilities/ImageUtils.swift
import UIKit

enum ImageUtils {

    /// Compress image to JPEG with target max size in bytes
    static func compressImage(_ image: UIImage, maxBytes: Int = 1_000_000) -> Data? {
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let data = image.jpegData(compressionQuality: quality),
               data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }
        return image.jpegData(compressionQuality: 0.1)
    }

    /// Generate a square thumbnail
    static func generateThumbnail(_ image: UIImage, size: CGFloat = 300) -> Data? {
        let targetSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            // Center-crop to square
            let aspectWidth = size / image.size.width
            let aspectHeight = size / image.size.height
            let scale = max(aspectWidth, aspectHeight)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (size - scaledSize.width) / 2,
                y: (size - scaledSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
```

**Step 2: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 3: Commit**

```bash
git add intelli-closet/Utilities/ImageUtils.swift
git commit -m "feat: add image compression and thumbnail utilities"
```

---
### Task 8: Add Clothing Flow — Photo Capture & AI Analysis

**Files:**
- Create: `intelli-closet/Views/AddClothing/PhotoPickerView.swift`
- Create: `intelli-closet/Views/AddClothing/AnalysisProgressView.swift`
- Create: `intelli-closet/Views/AddClothing/ClothingEditView.swift`
- Create: `intelli-closet/ViewModels/AddClothingViewModel.swift`
- Modify: `intelli-closet/Views/AddClothing/AddClothingView.swift`

**Step 1: Create AddClothingViewModel**

```swift
// intelli-closet/ViewModels/AddClothingViewModel.swift
import SwiftUI
import SwiftData
import PhotosUI

@Observable
class AddClothingViewModel {
    var selectedPhoto: PhotosPickerItem?
    var capturedImage: UIImage?
    var analysisResult: ClothingAnalysisResult?
    var isAnalyzing = false
    var errorMessage: String?
    var showCamera = false

    // Editable fields (populated from AI analysis, user can modify)
    var name = ""
    var category: ClothingCategory = .top
    var subcategory = ""
    var primaryColor = ""
    var secondaryColor = ""
    var material = ""
    var warmthLevel = 3
    var styleTags: [String] = []
    var fit = ""
    var itemDescription = ""

    enum State {
        case pickPhoto
        case analyzing
        case invalidPhoto(reason: String)
        case editResult
    }

    var state: State = .pickPhoto

    func handleSelectedPhoto() async {
        guard let item = selectedPhoto,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        capturedImage = image
        await analyzeImage(image)
    }

    func handleCapturedImage(_ image: UIImage) async {
        capturedImage = image
        await analyzeImage(image)
    }

    func analyzeImage(_ image: UIImage) async {
        guard let imageData = ImageUtils.compressImage(image) else { return }
        state = .analyzing
        isAnalyzing = true
        errorMessage = nil

        do {
            let result = try await AliyunService.shared.analyzeClothing(imageData: imageData)
            analysisResult = result

            if result.isValid {
                name = result.name ?? ""
                category = ClothingCategory(rawValue: result.category ?? "") ?? .top
                subcategory = result.subcategory ?? ""
                primaryColor = result.primaryColor ?? ""
                secondaryColor = result.secondaryColor ?? ""
                material = result.material ?? ""
                warmthLevel = result.warmthLevel ?? 3
                styleTags = result.styleTags ?? []
                fit = result.fit ?? ""
                itemDescription = result.description ?? ""
                state = .editResult
            } else {
                state = .invalidPhoto(reason: result.invalidReason ?? "照片质量不佳")
            }
        } catch {
            errorMessage = error.localizedDescription
            state = .pickPhoto
        }
        isAnalyzing = false
    }

    func saveClothing(modelContext: ModelContext) -> Bool {
        guard let image = capturedImage,
              let photo = ImageUtils.compressImage(image),
              let thumbnail = ImageUtils.generateThumbnail(image) else { return false }

        let item = ClothingItem(
            name: name,
            photo: photo,
            thumbnail: thumbnail,
            category: category,
            subcategory: subcategory,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor.isEmpty ? nil : secondaryColor,
            material: material,
            warmthLevel: warmthLevel,
            styleTags: styleTags,
            fit: fit,
            itemDescription: itemDescription
        )
        modelContext.insert(item)
        return true
    }

    func reset() {
        selectedPhoto = nil
        capturedImage = nil
        analysisResult = nil
        isAnalyzing = false
        errorMessage = nil
        state = .pickPhoto
        name = ""
        subcategory = ""
        primaryColor = ""
        secondaryColor = ""
        material = ""
        warmthLevel = 3
        styleTags = []
        fit = ""
        itemDescription = ""
    }
}
```

**Step 2: Create AddClothingView with photo picker and camera**

```swift
// intelli-closet/Views/AddClothing/AddClothingView.swift
import SwiftUI
import PhotosUI

struct AddClothingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddClothingViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .pickPhoto:
                    PhotoPickerView(viewModel: viewModel)
                case .analyzing:
                    AnalysisProgressView()
                case .invalidPhoto(let reason):
                    invalidPhotoView(reason: reason)
                case .editResult:
                    ClothingEditView(viewModel: viewModel) {
                        if viewModel.saveClothing(modelContext: modelContext) {
                            viewModel.reset()
                        }
                    }
                }
            }
            .navigationTitle("添加衣物")
            .alert("出错了", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("确定") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func invalidPhotoView(reason: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("照片不太合适")
                .font(.title2.bold())
            Text(reason)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Button("重新选择") {
                viewModel.reset()
            }
            .buttonStyle(.borderedProminent)
            .tint(.mint)
        }
    }
}
```

**Step 3: Create PhotoPickerView**

```swift
// intelli-closet/Views/AddClothing/PhotoPickerView.swift
import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Bindable var viewModel: AddClothingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "tshirt")
                .font(.system(size: 80))
                .foregroundStyle(.mint.opacity(0.6))

            Text("拍照或选择一件衣物")
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.mint)
            }
            .padding(.horizontal, 40)
            Spacer()
        }
        .onChange(of: viewModel.selectedPhoto) {
            Task { await viewModel.handleSelectedPhoto() }
        }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraView { image in
                Task { await viewModel.handleCapturedImage(image) }
            }
        }
    }
}
```

**Step 4: Create AnalysisProgressView**

```swift
// intelli-closet/Views/AddClothing/AnalysisProgressView.swift
import SwiftUI

struct AnalysisProgressView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在分析衣物...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("AI 正在识别衣物属性")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}
```

**Step 5: Create ClothingEditView**

```swift
// intelli-closet/Views/AddClothing/ClothingEditView.swift
import SwiftUI

struct ClothingEditView: View {
    @Bindable var viewModel: AddClothingViewModel
    var onSave: () -> Void

    var body: some View {
        Form {
            if let image = viewModel.capturedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section("基本信息") {
                TextField("名称", text: $viewModel.name)
                Picker("类别", selection: $viewModel.category) {
                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                TextField("子类别", text: $viewModel.subcategory)
            }

            Section("外观") {
                TextField("主色", text: $viewModel.primaryColor)
                TextField("辅色（可选）", text: $viewModel.secondaryColor)
                TextField("材质", text: $viewModel.material)
                TextField("版型", text: $viewModel.fit)
            }

            Section("保暖等级") {
                Picker("保暖等级", selection: $viewModel.warmthLevel) {
                    Text("1 - 轻薄").tag(1)
                    Text("2 - 较薄").tag(2)
                    Text("3 - 适中").tag(3)
                    Text("4 - 较厚").tag(4)
                    Text("5 - 厚实保暖").tag(5)
                }
            }

            Section("风格标签") {
                Text(viewModel.styleTags.joined(separator: "、"))
                    .foregroundStyle(.secondary)
                // TODO: tag editor for MVP simplicity, display only
            }

            Section("AI 描述") {
                Text(viewModel.itemDescription)
                    .foregroundStyle(.secondary)
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("保存") { onSave() }
                    .tint(.mint)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("重拍") { viewModel.reset() }
            }
        }
    }
}
```

**Step 6: Create a basic CameraView wrapper**

```swift
// intelli-closet/Views/AddClothing/CameraView.swift
import SwiftUI

struct CameraView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCapture: onCapture) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onCapture: (UIImage) -> Void
        init(onCapture: @escaping (UIImage) -> Void) { self.onCapture = onCapture }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
```

**Step 7: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: add clothing photo capture and AI analysis flow"
```

---
### Task 9: Wardrobe Browse & Edit

**Files:**
- Create: `intelli-closet/Views/Wardrobe/ClothingGridItem.swift`
- Create: `intelli-closet/Views/Wardrobe/ClothingDetailView.swift`
- Create: `intelli-closet/Views/Wardrobe/ClothingDetailEditView.swift`
- Modify: `intelli-closet/Views/Wardrobe/WardrobeView.swift`

**Step 1: Create ClothingGridItem**

```swift
// intelli-closet/Views/Wardrobe/ClothingGridItem.swift
import SwiftUI

struct ClothingGridItem: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 4) {
            if let uiImage = UIImage(data: item.thumbnail) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 110, height: 110)
            }
            Text(item.name)
                .font(.caption)
                .lineLimit(1)
        }
    }
}
```

**Step 2: Update WardrobeView with grid and filtering**

```swift
// intelli-closet/Views/Wardrobe/WardrobeView.swift
import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var allItems: [ClothingItem]
    @State private var selectedCategory: ClothingCategory?
    @State private var searchText = ""

    private var filteredItems: [ClothingItem] {
        allItems.filter { item in
            if let cat = selectedCategory, item.category != cat { return false }
            if !searchText.isEmpty {
                let query = searchText.lowercased()
                return item.name.lowercased().contains(query)
                    || item.primaryColor.lowercased().contains(query)
                    || item.styleTags.contains(where: { $0.lowercased().contains(query) })
            }
            return true
        }
    }

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                // Category filter
                Picker("类别", selection: $selectedCategory) {
                    Text("全部").tag(nil as ClothingCategory?)
                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat as ClothingCategory?)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "衣橱空空如也",
                        systemImage: "tshirt",
                        description: Text("去添加页面拍照上传你的衣物吧")
                    )
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(filteredItems) { item in
                            NavigationLink(value: item) {
                                ClothingGridItem(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("我的衣橱")
            .searchable(text: $searchText, prompt: "搜索衣物")
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
        }
    }
}
```

**Step 3: Create ClothingDetailView**

```swift
// intelli-closet/Views/Wardrobe/ClothingDetailView.swift
import SwiftUI

struct ClothingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let item: ClothingItem
    @State private var isEditing = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let uiImage = UIImage(data: item.photo) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(item.name)
                        .font(.title2.bold())

                    attributeRow("类别", "\(item.categoryRaw) · \(item.subcategory)")
                    attributeRow("主色", item.primaryColor)
                    if let secondary = item.secondaryColor {
                        attributeRow("辅色", secondary)
                    }
                    attributeRow("材质", item.material)
                    attributeRow("保暖等级", "\(item.warmthLevel)/5")
                    attributeRow("版型", item.fit)
                    attributeRow("风格", item.styleTags.joined(separator: "、"))

                    Divider()
                    Text(item.itemDescription)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("编辑") { isEditing = true }
                    Button("删除", role: .destructive) { showDeleteConfirm = true }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                ClothingDetailEditView(item: item)
            }
        }
        .confirmationDialog("确定删除这件衣物？", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
        }
    }

    private func attributeRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
            Text(value)
        }
        .font(.subheadline)
    }
}
```

**Step 4: Create ClothingDetailEditView**

```swift
// intelli-closet/Views/Wardrobe/ClothingDetailEditView.swift
import SwiftUI

struct ClothingDetailEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ClothingItem

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $item.name)
                Picker("类别", selection: $item.category) {
                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                TextField("子类别", text: $item.subcategory)
            }

            Section("外观") {
                TextField("主色", text: $item.primaryColor)
                TextField("辅色", text: Binding(
                    get: { item.secondaryColor ?? "" },
                    set: { item.secondaryColor = $0.isEmpty ? nil : $0 }
                ))
                TextField("材质", text: $item.material)
                TextField("版型", text: $item.fit)
            }

            Section("保暖等级") {
                Picker("保暖等级", selection: $item.warmthLevel) {
                    Text("1 - 轻薄").tag(1)
                    Text("2 - 较薄").tag(2)
                    Text("3 - 适中").tag(3)
                    Text("4 - 较厚").tag(4)
                    Text("5 - 厚实保暖").tag(5)
                }
            }
        }
        .navigationTitle("编辑衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("完成") { dismiss() }
                    .tint(.mint)
            }
        }
    }
}
```

**Step 5: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: add wardrobe browsing, detail view, and editing"
```

---
### Task 10: Smart Recommendation Flow

**Files:**
- Create: `intelli-closet/ViewModels/RecommendViewModel.swift`
- Create: `intelli-closet/Views/Recommend/OccasionPickerView.swift`
- Create: `intelli-closet/Views/Recommend/RecommendProgressView.swift`
- Create: `intelli-closet/Views/Recommend/OutfitResultView.swift`
- Modify: `intelli-closet/Views/Recommend/RecommendView.swift`

**Step 1: Create RecommendViewModel**

```swift
// intelli-closet/ViewModels/RecommendViewModel.swift
import SwiftUI
import SwiftData

@Observable
class RecommendViewModel {
    // Input
    var occasion = ""
    var customOccasion = ""
    var outfitCount = 2

    // Progress
    enum Step: String {
        case idle
        case fetchingWeather = "正在获取天气信息..."
        case filtering = "正在从衣橱中筛选候选衣物..."
        case textSelecting = "正在分析搭配方案..."
        case multimodalSelecting = "正在审美精选..."
        case done
        case error
    }

    var currentStep: Step = .idle
    var weatherInfo: WeatherInfo?
    var candidateCount = 0
    var shortlistCount = 0
    var streamedText = ""
    var outfits: [OutfitRecommendation] = []
    var errorMessage: String?

    // Weather fallback
    var showCityInput = false
    var cityInput = ""
    var showManualWeather = false
    var manualWeatherInput = ""

    let presetOccasions = ["上班", "逛街", "参加party", "遛狗", "约会", "运动"]

    var selectedOccasion: String {
        occasion == "自定义" ? customOccasion : occasion
    }

    func startRecommendation(allItems: [ClothingItem]) async {
        guard !selectedOccasion.isEmpty else { return }
        outfits = []
        streamedText = ""
        errorMessage = nil

        // Step 1: Weather
        currentStep = .fetchingWeather
        do {
            weatherInfo = try await WeatherService.shared.fetchWeather()
        } catch {
            // Fallback: ask for city
            showCityInput = true
            return
        }

        await continueWithWeather(allItems: allItems)
    }

    func retryWithCity(allItems: [ClothingItem]) async {
        showCityInput = false
        currentStep = .fetchingWeather
        do {
            weatherInfo = try await WeatherService.shared.fetchWeatherByCity(cityInput)
        } catch {
            // Final fallback: manual weather
            showManualWeather = true
            return
        }
        await continueWithWeather(allItems: allItems)
    }

    func retryWithManualWeather(allItems: [ClothingItem]) async {
        showManualWeather = false
        // Create a rough WeatherInfo from user description
        weatherInfo = WeatherInfo(
            temperature: 20, feelsLike: 20,
            condition: manualWeatherInput,
            humidity: 0.5, windSpeed: 10
        )
        await continueWithWeather(allItems: allItems)
    }

    private func continueWithWeather(allItems: [ClothingItem]) async {
        guard let weather = weatherInfo else { return }

        // Step 2: Local filter
        currentStep = .filtering
        let candidates = LocalFilterService.filterCandidates(
            allItems: allItems, weather: weather, occasion: selectedOccasion
        )
        candidateCount = candidates.count

        guard candidates.count >= 2 else {
            errorMessage = "衣橱中符合条件的衣物太少，请添加更多衣物"
            currentStep = .error
            return
        }

        // Step 3: Text selection
        currentStep = .textSelecting
        let shortlistedIds: [UUID]
        do {
            shortlistedIds = try await AliyunService.shared.textSelectOutfits(
                candidates: candidates, occasion: selectedOccasion, weather: weather
            )
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .error
            return
        }

        let shortlisted = candidates.filter { shortlistedIds.contains($0.id) }
        shortlistCount = shortlisted.count

        // If text selection returned too few, use all candidates
        let finalCandidates = shortlisted.count >= 4 ? shortlisted : candidates

        // Step 4: Multimodal recommendation
        currentStep = .multimodalSelecting
        streamedText = ""

        let stream = AliyunService.shared.multimodalRecommend(
            items: finalCandidates, occasion: selectedOccasion,
            weather: weather, count: outfitCount
        )

        do {
            for try await chunk in stream {
                streamedText += chunk
            }
        } catch {
            errorMessage = error.localizedDescription
            currentStep = .error
            return
        }

        // Parse the streamed JSON result
        parseOutfits(from: streamedText, allItems: finalCandidates)
        currentStep = .done
    }

    private func parseOutfits(from text: String, allItems: [ClothingItem]) {
        // Extract JSON from potential markdown code blocks
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let outfitArray = json["outfits"] as? [[String: Any]] else { return }

        let itemMap = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id.uuidString, $0) })

        outfits = outfitArray.compactMap { outfit in
            guard let topId = outfit["topId"] as? String,
                  let bottomId = outfit["bottomId"] as? String,
                  let reasoning = outfit["reasoning"] as? String,
                  let top = itemMap[topId],
                  let bottom = itemMap[bottomId] else { return nil }
            return OutfitRecommendation(top: top, bottom: bottom, reasoning: reasoning)
        }
    }

    func reset() {
        currentStep = .idle
        occasion = ""
        customOccasion = ""
        outfits = []
        streamedText = ""
        errorMessage = nil
    }
}
```

**Step 2: Create OccasionPickerView**

```swift
// intelli-closet/Views/Recommend/OccasionPickerView.swift
import SwiftUI

struct OccasionPickerView: View {
    @Bindable var viewModel: RecommendViewModel
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.mint.opacity(0.6))

            Text("今天穿什么？")
                .font(.title2.bold())

            VStack(spacing: 12) {
                Text("选择出门目的")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 10) {
                    ForEach(viewModel.presetOccasions, id: \.self) { occ in
                        Button(occ) {
                            viewModel.occasion = occ
                        }
                        .buttonStyle(.bordered)
                        .tint(viewModel.occasion == occ ? .mint : .gray)
                    }
                    Button("自定义") {
                        viewModel.occasion = "自定义"
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.occasion == "自定义" ? .mint : .gray)
                }

                if viewModel.occasion == "自定义" {
                    TextField("输入出门目的", text: $viewModel.customOccasion)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                }
            }

            Stepper("推荐套数：\(viewModel.outfitCount)", value: $viewModel.outfitCount, in: 1...3)
                .padding(.horizontal, 40)

            Button("开始推荐") { onStart() }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
                .disabled(viewModel.selectedOccasion.isEmpty)

            Spacer()
        }
        .padding()
    }
}
```

**Step 3: Create RecommendProgressView**

```swift
// intelli-closet/Views/Recommend/RecommendProgressView.swift
import SwiftUI

struct RecommendProgressView: View {
    let viewModel: RecommendViewModel

    private var steps: [(label: String, step: RecommendViewModel.Step, detail: String?)] {
        [
            ("☁️ 获取天气信息", .fetchingWeather, weatherInfo),
            ("👔 筛选候选衣物", .filtering, filterDetail),
            ("🤔 分析搭配方案", .textSelecting, shortlistDetail),
            ("👀 审美精选", .multimodalSelecting, nil)
        ]
    }

    private var weatherInfo: String? {
        viewModel.weatherInfo.map { "\($0.summary)" }
    }

    private var filterDetail: String? {
        viewModel.candidateCount > 0 ? "已筛出 \(viewModel.candidateCount) 件候选" : nil
    }

    private var shortlistDetail: String? {
        viewModel.shortlistCount > 0 ? "已选出 \(viewModel.shortlistCount) 件候选" : nil
    }

    private let allSteps: [RecommendViewModel.Step] = [
        .fetchingWeather, .filtering, .textSelecting, .multimodalSelecting
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Spacer()

            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                let stepIndex = allSteps.firstIndex(of: step.step) ?? 0
                let currentIndex = allSteps.firstIndex(of: viewModel.currentStep) ?? 0
                let isCompleted = stepIndex < currentIndex
                let isCurrent = step.step == viewModel.currentStep

                HStack(spacing: 12) {
                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.mint)
                    } else if isCurrent {
                        ProgressView()
                    } else {
                        Image(systemName: "circle")
                            .foregroundStyle(.gray.opacity(0.3))
                    }

                    VStack(alignment: .leading) {
                        Text(step.label)
                            .font(.body)
                            .foregroundStyle(isCurrent || isCompleted ? .primary : .tertiary)
                        if let detail = step.detail, isCompleted || isCurrent {
                            Text(detail)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            if viewModel.currentStep == .multimodalSelecting && !viewModel.streamedText.isEmpty {
                Divider()
                Text(viewModel.streamedText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
```

**Step 4: Create OutfitResultView**

```swift
// intelli-closet/Views/Recommend/OutfitResultView.swift
import SwiftUI

struct OutfitResultView: View {
    let outfits: [OutfitRecommendation]
    var onReset: () -> Void

    var body: some View {
        VStack {
            TabView {
                ForEach(outfits) { outfit in
                    ScrollView {
                        VStack(spacing: 16) {
                            Text("搭配方案")
                                .font(.headline)

                            HStack(spacing: 12) {
                                clothingCard(outfit.top, label: "上装")
                                clothingCard(outfit.bottom, label: "下装")
                            }
                            .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("推荐理由")
                                    .font(.subheadline.bold())
                                Text(outfit.reasoning)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button("重新推荐") { onReset() }
                .buttonStyle(.bordered)
                .tint(.mint)
                .padding(.bottom)
        }
    }

    private func clothingCard(_ item: ClothingItem, label: String) -> some View {
        VStack(spacing: 6) {
            if let uiImage = UIImage(data: item.photo) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Text(item.name)
                .font(.caption.bold())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
```

**Step 5: Update RecommendView to orchestrate the flow**

```swift
// intelli-closet/Views/Recommend/RecommendView.swift
import SwiftUI
import SwiftData

struct RecommendView: View {
    @Query private var allItems: [ClothingItem]
    @State private var viewModel = RecommendViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .idle:
                    OccasionPickerView(viewModel: viewModel) {
                        Task { await viewModel.startRecommendation(allItems: allItems) }
                    }
                case .fetchingWeather, .filtering, .textSelecting, .multimodalSelecting:
                    RecommendProgressView(viewModel: viewModel)
                case .done:
                    OutfitResultView(outfits: viewModel.outfits) {
                        viewModel.reset()
                    }
                case .error:
                    errorView
                }
            }
            .navigationTitle("智能推荐")
            .alert("定位失败", isPresented: $viewModel.showCityInput) {
                TextField("输入城市名", text: $viewModel.cityInput)
                Button("确定") {
                    Task { await viewModel.retryWithCity(allItems: allItems) }
                }
                Button("手动输入天气") { viewModel.showManualWeather = true }
            } message: {
                Text("无法获取定位，请手动输入所在城市")
            }
            .alert("获取天气失败", isPresented: $viewModel.showManualWeather) {
                TextField("描述今天的天气", text: $viewModel.manualWeatherInput)
                Button("确定") {
                    Task { await viewModel.retryWithManualWeather(allItems: allItems) }
                }
            } message: {
                Text("请直接描述天气情况，如"晴天，约25度"")
            }
        }
    }

    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            Text(viewModel.errorMessage ?? "发生未知错误")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") { viewModel.reset() }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
        }
        .padding()
    }
}
```

**Step 6: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 7: Commit**

```bash
git add -A
git commit -m "feat: add smart recommendation flow with two-stage AI selection"
```

---
### Task 11: Profile View

**Files:**
- Create: `intelli-closet/ViewModels/ProfileViewModel.swift`
- Modify: `intelli-closet/Views/Profile/ProfileView.swift`

**Step 1: Create ProfileViewModel**

```swift
// intelli-closet/ViewModels/ProfileViewModel.swift
import SwiftUI
import SwiftData
import PhotosUI

@Observable
class ProfileViewModel {
    var height: String = ""
    var weight: String = ""
    var headshotItem: PhotosPickerItem?
    var fullBodyItem: PhotosPickerItem?
    var headshotImage: UIImage?
    var fullBodyImage: UIImage?
    var isSaved = false

    func load(from profile: UserProfile?) {
        guard let profile else { return }
        height = profile.height.map { String(Int($0)) } ?? ""
        weight = profile.weight.map { String(Int($0)) } ?? ""
        if let data = profile.headshotPhoto { headshotImage = UIImage(data: data) }
        if let data = profile.fullBodyPhoto { fullBodyImage = UIImage(data: data) }
    }

    func save(profile: UserProfile, modelContext: ModelContext) {
        profile.height = Double(height)
        profile.weight = Double(weight)
        if let img = headshotImage {
            profile.headshotPhoto = ImageUtils.compressImage(img, maxBytes: 500_000)
        }
        if let img = fullBodyImage {
            profile.fullBodyPhoto = ImageUtils.compressImage(img, maxBytes: 1_000_000)
        }
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSaved = false
        }
    }

    func handleHeadshotPick() async {
        guard let item = headshotItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        headshotImage = image
    }

    func handleFullBodyPick() async {
        guard let item = fullBodyItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        fullBodyImage = image
    }
}
```

**Step 2: Update ProfileView**

```swift
// intelli-closet/Views/Profile/ProfileView.swift
import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var viewModel = ProfileViewModel()

    private var profile: UserProfile {
        if let existing = profiles.first { return existing }
        let new = UserProfile()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("身体信息") {
                    HStack {
                        Text("身高")
                        TextField("cm", text: $viewModel.height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("体重")
                        TextField("kg", text: $viewModel.weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("大头照") {
                    photoSection(
                        image: viewModel.headshotImage,
                        selection: $viewModel.headshotItem
                    )
                }

                Section("全身照") {
                    photoSection(
                        image: viewModel.fullBodyImage,
                        selection: $viewModel.fullBodyItem
                    )
                }

                Section {
                    Button("保存") {
                        viewModel.save(profile: profile, modelContext: modelContext)
                    }
                    .frame(maxWidth: .infinity)
                    .tint(.mint)
                }
            }
            .navigationTitle("我的")
            .onAppear { viewModel.load(from: profiles.first) }
            .onChange(of: viewModel.headshotItem) {
                Task { await viewModel.handleHeadshotPick() }
            }
            .onChange(of: viewModel.fullBodyItem) {
                Task { await viewModel.handleFullBodyPick() }
            }
            .overlay {
                if viewModel.isSaved {
                    Text("已保存 ✓")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: viewModel.isSaved)
        }
    }

    private func photoSection(image: UIImage?, selection: Binding<PhotosPickerItem?>) -> some View {
        VStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            PhotosPicker(selection: selection, matching: .images) {
                Label(image == nil ? "选择照片" : "更换照片", systemImage: "photo")
            }
            .tint(.mint)
        }
    }
}
```

**Step 3: Build and verify**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: add user profile view with photo upload"
```

---
### Task 12: Xcode Project Configuration & Permissions

**Files:**
- Modify: `intelli-closet.xcodeproj/project.pbxproj` (via Xcode settings)

**Step 1: Add required capabilities and permissions**

In the Xcode project, ensure the following are configured:

1. **Info.plist entries** (add to target):
   - `NSLocationWhenInUseUsageDescription`: "需要获取您的位置以查询当地天气，为您推荐合适的穿搭"
   - `NSCameraUsageDescription`: "需要使用相机拍摄衣物照片"
   - `NSPhotoLibraryUsageDescription`: "需要访问相册以选择衣物照片"

2. **Capabilities**:
   - Add WeatherKit capability to the target (requires Apple Developer account)

3. **Add all new Swift files to the Xcode project**:
   - Ensure all files under `Models/`, `Services/`, `ViewModels/`, `Views/`, `Utilities/` are included in the target's Compile Sources build phase.

**Step 2: Build and verify full app**

Run: `xcodebuild build -project intelli-closet.xcodeproj -scheme intelli-closet -destination 'platform=iOS Simulator,name=iPhone 16'`
Expected: BUILD SUCCEEDED with zero errors

**Step 3: Commit**

```bash
git add -A
git commit -m "chore: configure permissions and Xcode project settings"
```

---

### Task 13: End-to-End Smoke Test

**Step 1: Run the app in simulator**

Launch the app in iOS Simulator and verify:

1. Tab bar shows 4 tabs with correct icons and labels
2. **添加 tab**: Can open photo picker, select an image
3. **衣橱 tab**: Shows empty state message when no items exist
4. **推荐 tab**: Shows occasion picker with preset options
5. **我的 tab**: Shows profile form with height/weight fields and photo pickers

**Step 2: Test with a real clothing photo**

1. Add a clothing photo via the 添加 tab
2. Verify AI analysis returns and populates the edit form
3. Save the item
4. Switch to 衣橱 tab and verify the item appears in the grid
5. Tap the item and verify detail view shows all attributes
6. Edit an attribute and verify it persists

**Step 3: Test recommendation flow (requires 4+ clothing items)**

1. Add at least 4 items (2 tops, 2 bottoms)
2. Go to 推荐 tab, select an occasion
3. Verify progress steps display correctly
4. Verify recommendation results show outfit collages with reasoning

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete Intelli-Closet MVP"
```
