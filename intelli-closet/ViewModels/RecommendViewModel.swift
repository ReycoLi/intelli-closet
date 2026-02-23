import Foundation
import SwiftUI

@Observable
class RecommendViewModel {

    enum ProgressStep: String {
        case idle
        case fetchingWeather
        case filtering
        case preSelecting    // two-stage: text pre-selection
        case recommending    // streaming multimodal recommendation
        case done
        case error
    }

    // Input
    var occasion: String = ""
    var customOccasion: String = ""
    var outfitCount: Int = 2

    // Progress
    var currentStep: ProgressStep = .idle

    // State
    var weatherInfo: WeatherInfo?
    var candidateCount: Int = 0
    var topCount: Int = 0
    var bottomCount: Int = 0
    var streamedText: String = ""
    var outfits: [OutfitRecommendation] = []
    var errorMessage: String?

    // Weather fallback
    var showCityInput: Bool = false
    var cityInput: String = ""
    var showManualWeather: Bool = false
    var manualWeatherInput: String = ""

    let presetOccasions = ["上班", "逛街", "参加party", "遛狗", "约会", "运动"]

    var selectedOccasion: String {
        occasion == "自定义" ? customOccasion : occasion
    }

    // MARK: - Main Flow

    func startRecommendation(allItems: [ClothingItem]) async {
        currentStep = .fetchingWeather
        errorMessage = nil

        do {
            let weather = try await WeatherService.shared.fetchWeather()
            weatherInfo = weather
            await continueWithWeather(allItems: allItems)
        } catch {
            showCityInput = true
            currentStep = .idle
        }
    }

    func retryWithCity(allItems: [ClothingItem]) async {
        currentStep = .fetchingWeather
        showCityInput = false

        do {
            let weather = try await WeatherService.shared.fetchWeatherByCity(cityInput)
            weatherInfo = weather
            await continueWithWeather(allItems: allItems)
        } catch {
            showManualWeather = true
            currentStep = .idle
        }
    }

    func retryWithManualWeather(allItems: [ClothingItem]) async {
        showManualWeather = false
        currentStep = .fetchingWeather

        let weather = WeatherInfo(
            temperature: 20,
            feelsLike: 20,
            condition: manualWeatherInput,
            humidity: 0.5,
            windSpeed: 10
        )
        weatherInfo = weather
        await continueWithWeather(allItems: allItems)
    }

    // MARK: - Tiered Recommendation

    private func continueWithWeather(allItems: [ClothingItem]) async {
        guard let weather = weatherInfo else { return }

        do {
            // Step 1: Local filter
            currentStep = .filtering
            let candidates = LocalFilterService.filterCandidates(
                allItems: allItems,
                weather: weather,
                occasion: selectedOccasion
            )
            candidateCount = candidates.count

            let tops = candidates.filter { $0.categoryRaw == "上装" }
            let bottoms = candidates.filter { $0.categoryRaw == "下装" }
            topCount = tops.count
            bottomCount = bottoms.count
            let possibleOutfits = min(tops.count, bottoms.count)

            // Check: enough to form outfits?
            if possibleOutfits < 3 {
                currentStep = .error
                if tops.isEmpty {
                    errorMessage = "衣橱中没有合适的上装，请先添加更多上装"
                } else if bottoms.isEmpty {
                    errorMessage = "衣橱中没有合适的下装，请先添加更多下装"
                } else if tops.count < 3 {
                    errorMessage = "合适的上装只有\(tops.count)件，至少需要3件上装才能推荐"
                } else {
                    errorMessage = "合适的下装只有\(bottoms.count)件，至少需要3件下装才能推荐"
                }
                return
            }

            // Convert to DTOs
            let candidateDTOs = candidates.map { item in
                AliyunService.ClothingItemDTO(
                    id: item.id,
                    name: item.name,
                    categoryRaw: item.categoryRaw,
                    subcategory: item.subcategory,
                    primaryColor: item.primaryColor,
                    secondaryColor: item.secondaryColor,
                    material: item.material,
                    warmthLevel: item.warmthLevel,
                    styleTags: item.styleTags,
                    fit: item.fit,
                    itemDescription: item.itemDescription,
                    photoBase64: item.thumbnail.base64EncodedString()
                )
            }

            if possibleOutfits <= 8 {
                // Single-stage: direct multimodal streaming
                try await singleStageRecommend(dtos: candidateDTOs, candidates: candidates, weather: weather)
            } else {
                // Two-stage: text pre-select → multimodal
                try await twoStageRecommend(dtos: candidateDTOs, candidates: candidates, weather: weather)
            }
        } catch {
            currentStep = .error
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Single Stage (3-8 outfits possible)

    private func singleStageRecommend(dtos: [AliyunService.ClothingItemDTO], candidates: [ClothingItem], weather: WeatherInfo) async throws {
        currentStep = .recommending
        streamedText = ""

        var fullText = ""
        let stream = AliyunService.shared.multimodalRecommend(
            items: dtos,
            occasion: selectedOccasion,
            weather: weather,
            count: outfitCount
        )

        for try await chunk in stream {
            fullText += chunk
            streamedText = fullText
        }

        outfits = parseOutfits(from: fullText, allItems: candidates)
        currentStep = .done
    }

    // MARK: - Two Stage (>8 outfits possible)

    private func twoStageRecommend(dtos: [AliyunService.ClothingItemDTO], candidates: [ClothingItem], weather: WeatherInfo) async throws {
        // Stage 1: streaming text pre-selection
        currentStep = .preSelecting
        streamedText = ""

        let targetCount = min(16, dtos.count)
        var preSelectText = ""
        let preStream = AliyunService.shared.streamTextSelect(
            candidates: dtos,
            occasion: selectedOccasion,
            weather: weather,
            targetCount: targetCount
        )

        for try await chunk in preStream {
            preSelectText += chunk
            streamedText = preSelectText
        }

        // Parse selected IDs
        let cleaned = stripMarkdown(preSelectText)
        var shortlistDTOs = dtos
        if let jsonData = cleaned.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let ids = json["selectedIds"] as? [String] {
            let idSet = Set(ids.compactMap { UUID(uuidString: $0) })
            let filtered = dtos.filter { idSet.contains($0.id) }
            if filtered.count >= 6 {
                shortlistDTOs = filtered
            }
        }

        // Stage 2: multimodal recommendation
        currentStep = .recommending
        streamedText = ""

        var fullText = ""
        let stream = AliyunService.shared.multimodalRecommend(
            items: shortlistDTOs,
            occasion: selectedOccasion,
            weather: weather,
            count: outfitCount
        )

        for try await chunk in stream {
            fullText += chunk
            streamedText = fullText
        }

        outfits = parseOutfits(from: fullText, allItems: candidates)
        currentStep = .done
    }

    // MARK: - Parsing

    private func stripMarkdown(_ text: String) -> String {
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

    func parseOutfits(from text: String, allItems: [ClothingItem]) -> [OutfitRecommendation] {
        let cleaned = stripMarkdown(text)

        guard let jsonData = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let outfitsArray = json["outfits"] as? [[String: Any]] else {
            return []
        }

        var results: [OutfitRecommendation] = []
        for outfitDict in outfitsArray {
            guard let topIdString = outfitDict["topId"] as? String,
                  let bottomIdString = outfitDict["bottomId"] as? String,
                  let reasoning = outfitDict["reasoning"] as? String,
                  let topId = UUID(uuidString: topIdString),
                  let bottomId = UUID(uuidString: bottomIdString),
                  let top = allItems.first(where: { $0.id == topId }),
                  let bottom = allItems.first(where: { $0.id == bottomId }) else {
                continue
            }
            results.append(OutfitRecommendation(top: top, bottom: bottom, reasoning: reasoning))
        }
        return results
    }

    // MARK: - Reset

    func reset() {
        currentStep = .idle
        weatherInfo = nil
        candidateCount = 0
        topCount = 0
        bottomCount = 0
        streamedText = ""
        outfits = []
        errorMessage = nil
        showCityInput = false
        cityInput = ""
        showManualWeather = false
        manualWeatherInput = ""
    }
}