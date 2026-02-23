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
        ScrollView {
            VStack(spacing: 16) {
                // Clothing items
                HStack(spacing: 20) {
                    clothingCard(item: outfit.top, label: "上装")
                    clothingCard(item: outfit.bottom, label: "下装")
                }

                // Summary
                if !outfit.summary.isEmpty {
                    Text(outfit.summary)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Structured reasoning tags
                VStack(spacing: 10) {
                    reasoningRow(icon: "paintpalette", label: "颜色", text: outfit.colorMatch)
                    reasoningRow(icon: "sparkles", label: "风格", text: outfit.styleMatch)
                    reasoningRow(icon: "thermometer.medium", label: "天气", text: outfit.weatherFit)
                    reasoningRow(icon: "mappin.circle", label: "场合", text: outfit.occasionFit)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                .padding(.horizontal)

                // Aesthetic comment
                if !outfit.aesthetic.isEmpty {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "eye")
                            .foregroundStyle(.mint)
                            .padding(.top, 2)
                        Text(outfit.aesthetic)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .italic()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.mint.opacity(0.08))
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }

    private func reasoningRow(icon: String, label: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.mint)
                .frame(width: 20)
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .leading)
            Text(text)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func clothingCard(item: ClothingItem, label: String) -> some View {
        VStack(spacing: 8) {
            if let uiImage = UIImage(data: item.thumbnail) {
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