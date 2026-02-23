import SwiftUI

struct BatchAnalyzingView: View {
    let viewModel: AddClothingViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)

            Text("正在分析 \(viewModel.batchAnalyzedCount)/\(viewModel.batchItems.count) 件衣物…")
                .font(.headline)

            // Thumbnail grid showing status
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(viewModel.batchItems) { item in
                    ZStack {
                        Image(uiImage: item.image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        // Status overlay
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.black.opacity(0.3))
                            .frame(width: 100, height: 100)

                        statusIcon(for: item)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
    }

    @ViewBuilder
    private func statusIcon(for item: AddClothingViewModel.BatchItem) -> some View {
        switch item.status {
        case .analyzing:
            ProgressView()
                .tint(.white)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .font(.title)
                .foregroundStyle(.green)
        case .invalid:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.orange)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .font(.title)
                .foregroundStyle(.red)
        }
    }
}
