import SwiftUI
import SwiftData

struct AddClothingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [ClothingItem]
    @State private var viewModel = AddClothingViewModel()
    @State private var showSaveSuccess = false
    @State private var savedCount = 0

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
                        Button("重新选择") { viewModel.reset() }
                            .buttonStyle(.borderedProminent)
                            .tint(.mint)
                    }

                case .editResult:
                    ClothingEditView(
                        viewModel: viewModel,
                        onSave: {
                            if viewModel.saveClothing(modelContext: modelContext) {
                                savedCount = 1
                                showSaveSuccess = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                    showSaveSuccess = false
                                    viewModel.reset()
                                }
                            }
                        },
                        onCancel: { viewModel.reset() }
                    )

                case .batchAnalyzing:
                    BatchAnalyzingView(viewModel: viewModel)

                case .batchReview:
                    BatchReviewView(
                        viewModel: viewModel,
                        onCancel: { viewModel.reset() }
                    )
                }
            }
            .navigationTitle("添加衣物")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: viewModel.selectedPhotos) { _, newValue in
                guard !newValue.isEmpty else { return }
                Task {
                    await viewModel.handleSelectedPhotos(existingItems: allItems)
                }
            }
            .alert("错误", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("确定") { viewModel.errorMessage = nil }
            } message: {
                if let msg = viewModel.errorMessage { Text(msg) }
            }
            .overlay {
                if showSaveSuccess {
                    VStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.green)
                        Text("已保存\(savedCount)件衣物")
                            .font(.headline)
                    }
                    .padding(30)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }
}
