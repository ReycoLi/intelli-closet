//
//  ClothingDetailEditView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI

struct ClothingDetailEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var item: ClothingItem

    var body: some View {
        Form {
            Section("基本信息") {
                TextField("名称", text: $item.name)

                Picker("类别", selection: $item.category) {
                    ForEach(ClothingCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }

                TextField("子类别", text: $item.subcategory)
            }

            Section("外观") {
                TextField("主色", text: $item.primaryColor)

                TextField("辅色（可选）", text: Binding(
                    get: { item.secondaryColor ?? "" },
                    set: { newValue in
                        item.secondaryColor = newValue.isEmpty ? nil : newValue
                    }
                ))

                TextField("材质", text: $item.material)

                TextField("版型", text: $item.fit)
            }

            Section("保暖等级") {
                Picker("保暖等级", selection: $item.warmthLevel) {
                    ForEach(WarmthLevel.allCases, id: \.rawValue) { level in
                        Text(level.label).tag(level.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if let level = WarmthLevel(rawValue: item.warmthLevel) {
                    Text("\(level.temperatureRange) · \(level.examples)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("编辑衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("完成") {
                    dismiss()
                }
            }
        }
    }
}
