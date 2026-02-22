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
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddClothingViewModel()

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
                                dismiss()
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
            .toolbar {
                if case .pickPhoto = viewModel.state {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
}
