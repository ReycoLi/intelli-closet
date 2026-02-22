//
//  ClothingEditView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI

struct ClothingEditView: View {
    @Bindable var viewModel: AddClothingViewModel
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        Form {
            if let image = viewModel.capturedImage {
                Section {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Section("基本信息") {
                TextField("名称", text: $viewModel.name)

                Picker("分类", selection: $viewModel.category) {
                    ForEach(ClothingCategory.allCases, id: \.self) { category in
                        Text(category.rawValue).tag(category)
                    }
                }

                TextField("子分类", text: $viewModel.subcategory)
            }

            Section("外观") {
                TextField("主要颜色", text: $viewModel.primaryColor)
                TextField("次要颜色", text: $viewModel.secondaryColor)
                TextField("材质", text: $viewModel.material)
                TextField("版型", text: $viewModel.fit)
            }

            Section("保暖等级") {
                Picker("保暖等级", selection: $viewModel.warmthLevel) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("风格标签") {
                if !viewModel.styleTags.isEmpty {
                    Text(viewModel.styleTags.joined(separator: "、"))
                } else {
                    Text("无")
                        .foregroundStyle(.secondary)
                }
            }

            Section("AI 描述") {
                Text(viewModel.itemDescription)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("编辑衣物")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("重拍") {
                    onCancel()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("保存") {
                    onSave()
                }
                .disabled(viewModel.name.isEmpty)
            }
        }
    }
}
