import Foundation

struct OutfitRecommendation: Identifiable {
    let id = UUID()
    let top: ClothingItem
    let bottom: ClothingItem
    let reasoning: String
}
