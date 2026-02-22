//
//  ClothingItem.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import Foundation
import SwiftData

@Model
class ClothingItem {
    var id: UUID
    var name: String
    @Attribute(.externalStorage) var photo: Data
    @Attribute(.externalStorage) var thumbnail: Data
    var categoryRaw: String
    var subcategory: String
    var primaryColor: String
    var secondaryColor: String?
    var material: String
    var warmthLevel: Int
    var styleTags: [String]
    var fit: String
    var itemDescription: String
    var createdAt: Date

    var category: ClothingCategory {
        get { ClothingCategory(rawValue: categoryRaw) ?? .top }
        set { categoryRaw = newValue.rawValue }
    }

    init(
        name: String,
        photo: Data,
        thumbnail: Data,
        category: ClothingCategory,
        subcategory: String,
        primaryColor: String,
        secondaryColor: String? = nil,
        material: String,
        warmthLevel: Int,
        styleTags: [String],
        fit: String,
        itemDescription: String
    ) {
        self.id = UUID()
        self.name = name
        self.photo = photo
        self.thumbnail = thumbnail
        self.categoryRaw = category.rawValue
        self.subcategory = subcategory
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.material = material
        self.warmthLevel = warmthLevel
        self.styleTags = styleTags
        self.fit = fit
        self.itemDescription = itemDescription
        self.createdAt = Date()
    }
}
