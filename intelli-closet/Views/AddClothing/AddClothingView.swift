//
//  AddClothingView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI
import SwiftData

struct AddClothingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AddClothingViewModel()
    @State private var showSaveSuccess = false

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .pickPhoto:
                    PhotoPickerView(viewModel: viewModel)

                case .analyzing:
                    AnalysisProgressView()

                case .invalidPhoto(let reason):
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.orange)

                        Text(reason)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("重新选择") {
                            viewModel.reset()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.mint)
                    }

                case .editResult:
                    ClothingEditView(
                        viewModel: viewModel,
                        onSave: {
                            if viewModel.saveClothing(modelContext: modelContext) {
                                showSaveSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    showSaveSuccess = false
                                    viewModel.reset()
                                }
                            }
                        },
                        onCancel: {
                            viewModel.reset()
                        }
                    )
                }
            }
            .navigationTitle("添加衣物")
            .navigationBarTitleDisplayMode(.inline)
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .overlay {
                if showSaveSuccess {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("保存成功")
                            .font(.headline)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
