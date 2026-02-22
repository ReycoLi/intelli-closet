import SwiftUI

struct OutfitResultView: View {
    let outfits: [OutfitRecommendation]
    let onReset: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if outfits.isEmpty {
                Text("未能生成推荐")
                    .foregroundStyle(.secondary)
            } else {
                TabView {
                    ForEach(outfits) { outfit in
                        outfitCard(outfit)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }

            Button {
                onReset()
            } label: {
                Text("重新推荐")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mint)
                    )
                    .foregroundStyle(.white)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    private func outfitCard(_ outfit: OutfitRecommendation) -> some View {
        VStack(spacing: 20) {
            // Clothing items
            HStack(spacing: 20) {
                clothingCard(item: outfit.top, label: "上装")
                clothingCard(item: outfit.bottom, label: "下装")
            }
            .padding(.horizontal)

            // Reasoning
            ScrollView {
                Text(outfit.reasoning)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    private func clothingCard(item: ClothingItem, label: String) -> some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(data: item.photo) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 150, height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 150, height: 150)
            }

            Text(item.name)
                .font(.headline)
                .lineLimit(1)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
