import Foundation

struct OutfitRecommendation: Identifiable {
    let id = UUID()
    let top: ClothingItem
    let bottom: ClothingItem
    let summary: String
    let colorMatch: String
    let styleMatch: String
    let weatherFit: String
    let occasionFit: String
    let aesthetic: String
}
