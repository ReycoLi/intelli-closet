//
//  ClothingDetailView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI
import SwiftData

struct ClothingDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: ClothingItem

    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Full photo
                if let uiImage = UIImage(data: item.photo) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 350)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 350)
                }

                // Name
                Text(item.name)
                    .font(.title2)
                    .bold()

                // Attributes
                VStack(alignment: .leading, spacing: 8) {
                    AttributeRow(label: "类别", value: item.category.rawValue)
                    AttributeRow(label: "主色", value: item.primaryColor)
                    if let secondaryColor = item.secondaryColor {
                        AttributeRow(label: "辅色", value: secondaryColor)
                    }
                    AttributeRow(label: "材质", value: item.material)
                    AttributeRow(label: "保暖等级", value: "\(item.warmthLevel)")
                    AttributeRow(label: "版型", value: item.fit)
                    AttributeRow(label: "风格", value: item.styleTags.joined(separator: ", "))
                }

                Divider()

                // Description
                Text(item.itemDescription)
                    .font(.body)
            }
            .padding()
        }
        .navigationTitle("衣物详情")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("编辑") {
                        showEditSheet = true
                    }
                    Button("删除", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                ClothingDetailEditView(item: item)
            }
        }
        .confirmationDialog("确认删除", isPresented: $showDeleteConfirmation) {
            Button("删除", role: .destructive) {
                modelContext.delete(item)
                dismiss()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("确定要删除这件衣物吗？")
        }
    }
}

struct AttributeRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }
}
