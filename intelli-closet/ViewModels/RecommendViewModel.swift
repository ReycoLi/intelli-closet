import Foundation
import SwiftUI

@Observable
class RecommendViewModel {

    enum ProgressStep: String {
        case idle
        case fetchingWeather
        case filtering
        case textSelecting
        case multimodalSelecting
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
    var shortlistCount: Int = 0
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

    private func continueWithWeather(allItems: [ClothingItem]) async {
        guard let weather = weatherInfo else { return }

        do {
            // Step 2: Filter candidates
            currentStep = .filtering
            let candidates = LocalFilterService.filterCandidates(
                allItems: allItems,
                weather: weather,
                occasion: selectedOccasion
            )
            candidateCount = candidates.count

            guard candidates.count >= 2 else {
                currentStep = .error
                errorMessage = "候选衣物不足，请添加更多衣物"
                return
            }

            // Step 3: Text selection
            currentStep = .textSelecting
            let selectedIDs = try await AliyunService.shared.textSelectOutfits(
                candidates: candidates,
                occasion: selectedOccasion,
                weather: weather
            )

            let shortlist = candidates.filter { selectedIDs.contains($0.id) }
            shortlistCount = shortlist.count

            let finalCandidates = shortlist.count >= 4 ? shortlist : candidates

            // Step 4: Multimodal recommendation
            currentStep = .multimodalSelecting
            streamedText = ""

            var fullText = ""
            let stream = try await AliyunService.shared.multimodalRecommend(
                items: finalCandidates,
                occasion: selectedOccasion,
                weather: weather,
                count: outfitCount
            )

            for try await chunk in stream {
                fullText += chunk
                streamedText = fullText
            }

            // Parse outfits
            let parsedOutfits = parseOutfits(from: fullText, allItems: finalCandidates)
            outfits = parsedOutfits

            currentStep = .done
        } catch {
            currentStep = .error
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Parsing

    func parseOutfits(from text: String, allItems: [ClothingItem]) -> [OutfitRecommendation] {
        var cleanedText = text

        // Strip markdown code blocks
        if cleanedText.contains("```json") {
            cleanedText = cleanedText.replacingOccurrences(of: "```json", with: "")
            cleanedText = cleanedText.replacingOccurrences(of: "```", with: "")
        }

        guard let jsonData = cleanedText.data(using: .utf8),
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
        shortlistCount = 0
        streamedText = ""
        outfits = []
        errorMessage = nil
        showCityInput = false
        cityInput = ""
        showManualWeather = false
        manualWeatherInput = ""
    }
}
