import Foundation

nonisolated struct ClothingAnalysisResult: Codable, Sendable {
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
