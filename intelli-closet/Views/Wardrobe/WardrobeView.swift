//
//  WardrobeView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI
import SwiftData

struct WardrobeView: View {
    @Query(sort: \ClothingItem.createdAt, order: .reverse) private var allItems: [ClothingItem]

    @State private var selectedCategory: ClothingCategory?
    @State private var searchText = ""

    var filteredItems: [ClothingItem] {
        var items = allItems

        // Filter by category
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        // Filter by search text
        if !searchText.isEmpty {
            items = items.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.primaryColor.localizedCaseInsensitiveContains(searchText) ||
                item.styleTags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return items
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category picker
                    Picker("类别", selection: $selectedCategory) {
                        Text("全部").tag(nil as ClothingCategory?)
                        ForEach(ClothingCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as ClothingCategory?)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if filteredItems.isEmpty {
                        ContentUnavailableView(
                            "衣橱空空如也",
                            systemImage: "tshirt",
                            description: Text("添加第一件衣物开始管理你的衣橱")
                        )
                        .frame(maxHeight: .infinity)
                    } else {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 110), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(filteredItems) { item in
                                NavigationLink(value: item) {
                                    ClothingGridItem(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("我的衣橱")
            .searchable(text: $searchText, prompt: "搜索衣物")
            .navigationDestination(for: ClothingItem.self) { item in
                ClothingDetailView(item: item)
            }
        }
    }
}
