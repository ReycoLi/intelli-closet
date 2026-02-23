import Foundation

struct FilteredOutItem {
    let item: ClothingItem
    let reason: String
}

struct FilterResult {
    let candidates: [ClothingItem]
    let filteredOut: [FilteredOutItem]
    let warmthRange: String
    let styleFilter: String?
}

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
    ) -> FilterResult {
        let temp = weather.temperature

        let warmthDesc = WarmthLevel.filterDescription(for: Int(temp))
        let warmthCheck: (Int) -> Bool
        switch temp {
        case ..<10:
            warmthCheck = { $0 >= 3 }
        case 10..<20:
            warmthCheck = { $0 >= 2 && $0 <= 4 }
        case 20..<28:
            warmthCheck = { $0 <= 3 }
        default:
            warmthCheck = { $0 <= 2 }
        }

        var filteredOut: [FilteredOutItem] = []

        // Step 1: warmth filter
        var warmthPassed: [ClothingItem] = []
        for item in allItems {
            if warmthCheck(item.warmthLevel) {
                warmthPassed.append(item)
            } else {
                filteredOut.append(FilteredOutItem(
                    item: item,
                    reason: "\(item.name)是\(WarmthLevel(rawValue: item.warmthLevel)?.label ?? "未知")（等级\(item.warmthLevel)），不适合当前温度"
                ))
            }
        }

        // Step 2: style filter
        let relevantStyles = occasionStyleMap[occasion] ?? []
        if relevantStyles.isEmpty {
            return FilterResult(
                candidates: warmthPassed,
                filteredOut: filteredOut,
                warmthRange: warmthDesc,
                styleFilter: nil
            )
        }

        let styleDesc = "场合「\(occasion)」需要\(relevantStyles.joined(separator: "/"))风格"
        let styleSet = Set(relevantStyles)
        var stylePassed: [ClothingItem] = []
        var styleFilteredOut: [FilteredOutItem] = []

        for item in warmthPassed {
            if !Set(item.styleTags).isDisjoint(with: styleSet) {
                stylePassed.append(item)
            } else {
                styleFilteredOut.append(FilteredOutItem(
                    item: item,
                    reason: "\(item.name)风格\(item.styleTags.joined(separator: "/"))，不匹配\(occasion)"
                ))
            }
        }

        // If style filter is too aggressive, fall back to warmth-only
        if stylePassed.count >= 6 {
            filteredOut.append(contentsOf: styleFilteredOut)
            return FilterResult(
                candidates: stylePassed,
                filteredOut: filteredOut,
                warmthRange: warmthDesc,
                styleFilter: styleDesc
            )
        } else {
            return FilterResult(
                candidates: warmthPassed,
                filteredOut: filteredOut,
                warmthRange: warmthDesc,
                styleFilter: nil // fell back, style filter not applied
            )
        }
    }
}
