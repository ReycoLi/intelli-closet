import Foundation

actor AliyunService {
    static let shared = AliyunService()

    private let apiKey = Secrets.aliyunAPIKey
    private let baseURL = "https://dashscope.aliyuncs.com/compatible-mode/v1"

    enum AliyunError: LocalizedError {
        case requestFailed(String)
        case invalidResponse
        case streamingFailed(String)

        var errorDescription: String? {
            switch self {
            case .requestFailed(let message):
                return "请求失败: \(message)"
            case .invalidResponse:
                return "无效的响应"
            case .streamingFailed(let message):
                return "流式传输失败: \(message)"
            }
        }
    }

    struct ClothingItemDTO: Sendable {
        let id: UUID
        let name: String
        let categoryRaw: String
        let subcategory: String
        let primaryColor: String
        let secondaryColor: String?
        let material: String
        let warmthLevel: Int
        let styleTags: [String]
        let fit: String
        let itemDescription: String
        let photoBase64: String
    }

    private init() {}

    // MARK: - Clothing Analysis

    func analyzeClothing(imageData: Data) async throws -> ClothingAnalysisResult {
        let base64Image = imageData.base64EncodedString()
        let imageURL = "data:image/jpeg;base64,\(base64Image)"

        let systemPrompt = """
        你是一个专业的服装分析助手。请分析用户上传的服装照片，并按以下步骤处理：

        1. 首先检查照片质量：
           - 如果照片模糊、不完整、杂乱或无法清晰识别服装，返回 isValid=false 并说明原因
           - 如果照片清晰可用，继续分析

        2. 如果照片有效，提取以下信息并返回JSON格式：
           - name: 给服装起一个独特的、有美感的中文名称
           - category: 分类（上装/下装）
           - subcategory: 子分类（如：T恤、衬衫、牛仔裤等）
           - primaryColor: 主要颜色
           - secondaryColor: 次要颜色（如果有）
           - material: 材质
           - warmthLevel: 保暖程度（1-5，1最凉爽，5最保暖）
           - styleTags: 风格标签数组（如：["休闲", "运动", "商务"]）
           - fit: 版型（如：修身、宽松、标准）
           - description: 自然语言描述，包括质感、细节、搭配方向等

        3. 只返回JSON，不要包含其他内容

        JSON格式示例：
        {
          "isValid": true,
          "invalidReason": null,
          "name": "清新蓝调衬衫",
          "category": "上装",
          "subcategory": "衬衫",
          "primaryColor": "蓝色",
          "secondaryColor": "白色",
          "material": "棉质",
          "warmthLevel": 2,
          "styleTags": ["商务", "休闲"],
          "fit": "修身",
          "description": "这是一件浅蓝色棉质衬衫，质地柔软透气，适合春秋季节穿着。修身版型展现优雅气质，可搭配深色西裤或牛仔裤。"
        }
        """

        let requestBody: [String: Any] = [
            "model": "qwen-vl-max",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "image_url", "image_url": ["url": imageURL]]
                ]]
            ]
        ]

        let responseData = try await makeRequest(body: requestBody)
        let content = try extractContent(from: responseData)

        let cleaned = stripMarkdownCodeBlock(content)
        guard let jsonData = cleaned.data(using: .utf8) else {
            throw AliyunError.invalidResponse
        }

        return try JSONDecoder().decode(ClothingAnalysisResult.self, from: jsonData)
    }

    // MARK: - Text Selection (streaming, for two-stage path)

    nonisolated func streamTextSelect(candidates: [ClothingItemDTO], occasion: String, weather: WeatherInfo, targetCount: Int) -> AsyncThrowingStream<String, Error> {
        let candidatesList = candidates.map { item in
            """
            ID: \(item.id.uuidString)
            名称: \(item.name) | \(item.categoryRaw)-\(item.subcategory) | \(item.primaryColor) | 保暖\(item.warmthLevel)/5 | \(item.styleTags.joined(separator: ","))
            """
        }.joined(separator: "\n")

        let prompt = """
        你是专业服装搭配顾问。从以下\(candidates.count)件候选服装中，挑选\(targetCount)件最适合的单品。

        场合: \(occasion)
        天气: \(weather.summary)

        \(candidatesList)

        考虑天气适宜性、场合匹配、颜色风格协调性。
        只返回JSON：{"selectedIds": ["id1", "id2", ...]}
        """

        return makeStreamingRequest(prompt: prompt)
    }

    // MARK: - Multimodal Recommendation (streaming)

    nonisolated func multimodalRecommend(items: [ClothingItemDTO], occasion: String, weather: WeatherInfo, count: Int) -> AsyncThrowingStream<String, Error> {
        var contentArray: [[String: Any]] = []

        let prompt = """
        你是一个专业的服装搭配顾问。根据以下服装的实际照片和信息，推荐\(count)套搭配方案。

        场合: \(occasion)
        天气: \(weather.summary)

        服装信息：
        """
        contentArray.append(["type": "text", "text": prompt])

        for item in items {
            let imageURL = "data:image/jpeg;base64,\(item.photoBase64)"
            contentArray.append([
                "type": "image_url",
                "image_url": ["url": imageURL]
            ])
            let metadata = """

            ID: \(item.id.uuidString)
            名称: \(item.name)
            分类: \(item.categoryRaw)
            颜色: \(item.primaryColor)
            风格: \(item.styleTags.joined(separator: ", "))
            描述: \(item.itemDescription)
            """
            contentArray.append(["type": "text", "text": metadata])
        }

        let instruction = """

        请基于视觉美感推荐\(count)套搭配（每套包含一件上装和一件下装）。

        严格要求：每个字段必须具体有用，但限制在20字以内，只说最关键的一句。
        - colorMatch（≤20字）: 什么色配什么色、为什么好看（如"深灰配卡其，低饱和层次感"）
        - styleMatch（≤20字）: 版型/风格为什么搭（如"宽松卫衣配修身裤，松紧对比显腿长"）
        - weatherFit（≤20字）: 结合\(weather.temperature)°C说明（如"棉质保暖3级，6°C内搭够用"）
        - occasionFit（≤20字）: 为什么适合\(occasion)（如"休闲舒适，逛街走动不拘束"）
        - aesthetic（≤25字）: 整体氛围气质（如"日系文艺少年感，干净清爽给人好印象"）
        - summary（≤15字）: 一句话核心亮点

        只返回JSON格式：
        {"outfits": [{"topId": "id", "bottomId": "id", "summary": "亮点", "colorMatch": "颜色", "styleMatch": "风格", "weatherFit": "天气", "occasionFit": "场合", "aesthetic": "审美"}]}
        """
        contentArray.append(["type": "text", "text": instruction])

        return makeStreamingRequest(content: contentArray)
    }

    // MARK: - Private Helpers

    /// Streaming request with text-only prompt
    private nonisolated func makeStreamingRequest(prompt: String) -> AsyncThrowingStream<String, Error> {
        let requestBody: [String: Any] = [
            "model": "qwen3.5-plus",
            "messages": [["role": "user", "content": prompt]],
            "stream": true,
            "enable_thinking": false
        ]
        return executeStreamingRequest(body: requestBody)
    }

    /// Streaming request with multimodal content array
    private nonisolated func makeStreamingRequest(content: [[String: Any]]) -> AsyncThrowingStream<String, Error> {
        let requestBody: [String: Any] = [
            "model": "qwen3.5-plus",
            "messages": [["role": "user", "content": content]],
            "stream": true,
            "enable_thinking": false
        ]
        return executeStreamingRequest(body: requestBody)
    }

    private nonisolated func executeStreamingRequest(body: [String: Any]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    var request = URLRequest(url: URL(string: "\(self.baseURL)/chat/completions")!)
                    request.httpMethod = "POST"
                    request.timeoutInterval = 30
                    request.setValue("Bearer \(self.apiKey)", forHTTPHeaderField: "Authorization")
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, response) = try await URLSession.shared.bytes(for: request)

                    guard let httpResponse = response as? HTTPURLResponse,
                          (200...299).contains(httpResponse.statusCode) else {
                        throw AliyunError.invalidResponse
                    }

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let data = String(line.dropFirst(6))
                        if data == "[DONE]" { break }

                        if let jsonData = data.data(using: .utf8),
                           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let choices = json["choices"] as? [[String: Any]],
                           let delta = choices.first?["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            continuation.yield(content)
                        }
                    }

                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Non-streaming request (used for clothing analysis)
    private func makeRequest(body: [String: Any]) async throws -> Data {
        var request = URLRequest(url: URL(string: "\(baseURL)/chat/completions")!)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AliyunError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AliyunError.requestFailed(errorMessage)
        }

        return data
    }

    private func extractContent(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AliyunError.invalidResponse
        }
        return content
    }

    private func stripMarkdownCodeBlock(_ text: String) -> String {
        var cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleaned.hasPrefix("```json") {
            cleaned = String(cleaned.dropFirst("```json".count))
        } else if cleaned.hasPrefix("```") {
            cleaned = String(cleaned.dropFirst("```".count))
        }
        if cleaned.hasSuffix("```") {
            cleaned = String(cleaned.dropLast("```".count))
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}