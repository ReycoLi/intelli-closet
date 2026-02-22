//
//  ClothingGridItem.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI

struct ClothingGridItem: View {
    let item: ClothingItem

    var body: some View {
        VStack(spacing: 4) {
            if let uiImage = UIImage(data: item.thumbnail) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 110, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 110, height: 110)
            }

            Text(item.name)
                .font(.caption)
                .lineLimit(1)
                .frame(width: 110)
        }
    }
}
