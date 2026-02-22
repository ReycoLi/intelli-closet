import Foundation

struct LocalFilterService {

    private static let occasionStyleMap: [String: [String]] = [
        "上班": ["通勤", "正式"],
        "逛街": ["休闲", "街头"],
        "参加party": ["正式", "休闲"],
        "遛狗": ["休闲", "街头"],
        "约会": ["休闲", "通勤"],
        "运动": ["休闲", "街头"]
    ]

    static func filterCandidates(
        allItems: [ClothingItem],
        weather: WeatherInfo,
        occasion: String
    ) -> [ClothingItem] {
        let temp = weather.temperature

        let warmthFiltered = allItems.filter { item in
            switch temp {
            case ..<10:  return item.warmthLevel >= 3
            case 10..<20: return item.warmthLevel >= 2 && item.warmthLevel <= 4
            case 20..<28: return item.warmthLevel <= 3
            default:      return item.warmthLevel <= 2
            }
        }

        let relevantStyles = occasionStyleMap[occasion] ?? []
        if relevantStyles.isEmpty {
            return warmthFiltered
        }

        let styleMatched = warmthFiltered.filter { item in
            !Set(item.styleTags).isDisjoint(with: Set(relevantStyles))
        }

        return styleMatched.count >= 6 ? styleMatched : warmthFiltered
    }
}
