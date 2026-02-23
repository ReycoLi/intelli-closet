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

        let warmthDesc: String
        let warmthCheck: (Int) -> Bool
        switch temp {
        case ..<10:
            warmthDesc = "保暖≥3级（低温）"
            warmthCheck = { $0 >= 3 }
        case 10..<20:
            warmthDesc = "保暖2-4级（凉爽）"
            warmthCheck = { $0 >= 2 && $0 <= 4 }
        case 20..<28:
            warmthDesc = "保暖≤3级（温暖）"
            warmthCheck = { $0 <= 3 }
        default:
            warmthDesc = "保暖≤2级（炎热）"
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
                    reason: "\(item.name)保暖\(item.warmthLevel)级，不符合\(warmthDesc)"
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
