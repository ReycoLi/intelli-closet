import Foundation

enum WarmthLevel: Int, CaseIterable {
    case light = 1
    case breathable = 2
    case moderate = 3
    case warm = 4
    case heavy = 5

    var label: String {
        switch self {
        case .light: "轻薄"
        case .breathable: "透气"
        case .moderate: "适中"
        case .warm: "保暖"
        case .heavy: "厚实"
        }
    }

    var temperatureRange: String {
        switch self {
        case .light: "28°C以上"
        case .breathable: "20-28°C"
        case .moderate: "15-22°C"
        case .warm: "8-15°C"
        case .heavy: "8°C以下"
        }
    }

    var examples: String {
        switch self {
        case .light: "背心、短袖T恤"
        case .breathable: "衬衫、薄外套"
        case .moderate: "卫衣、薄毛衣"
        case .warm: "厚毛衣、夹克"
        case .heavy: "羽绒服、大衣"
        }
    }

    var description: String {
        "\(label) · \(temperatureRange) · \(examples)"
    }

    static func filterDescription(for temp: Int) -> String {
        switch temp {
        case ..<10:
            "当前\(temp)°C，需要保暖/厚实的衣物（等级3-5）"
        case 10..<20:
            "当前\(temp)°C，需要适中保暖的衣物（等级2-4）"
        case 20..<28:
            "当前\(temp)°C，需要轻薄透气的衣物（等级1-3）"
        default:
            "当前\(temp)°C，需要轻薄的衣物（等级1-2）"
        }
    }
}
