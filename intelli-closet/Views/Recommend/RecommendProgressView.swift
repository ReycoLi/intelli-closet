import SwiftUI

struct RecommendProgressView: View {
    let viewModel: RecommendViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Step 1: Fetching Weather
            stepRow(
                icon: "☁️",
                title: "获取天气信息",
                isCompleted: isStepCompleted(.fetchingWeather),
                isCurrent: viewModel.currentStep == .fetchingWeather,
                detail: isStepCompleted(.fetchingWeather) ? viewModel.weatherInfo?.summary : nil
            )

            // Step 2: Filtering
            stepRow(
                icon: "👔",
                title: "筛选候选衣物",
                isCompleted: isStepCompleted(.filtering),
                isCurrent: viewModel.currentStep == .filtering,
                detail: isStepCompleted(.filtering) ? "已筛出 \(viewModel.candidateCount) 件候选" : nil
            )

            // Step 3: Text Selecting
            stepRow(
                icon: "🤔",
                title: "分析搭配方案",
                isCompleted: isStepCompleted(.textSelecting),
                isCurrent: viewModel.currentStep == .textSelecting,
                detail: isStepCompleted(.textSelecting) ? "已选出 \(viewModel.shortlistCount) 件候选" : nil
            )

            // Step 4: Multimodal Selecting
            stepRow(
                icon: "👀",
                title: "审美精选",
                isCompleted: isStepCompleted(.multimodalSelecting),
                isCurrent: viewModel.currentStep == .multimodalSelecting,
                detail: nil
            )

            // Streamed text
            if viewModel.currentStep == .multimodalSelecting && !viewModel.streamedText.isEmpty {
                Divider()
                    .padding(.horizontal)

                ScrollView {
                    Text(viewModel.streamedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                }
                .frame(maxHeight: 150)
            }

            Spacer()
        }
        .padding()
    }

    private func stepRow(icon: String, title: String, isCompleted: Bool, isCurrent: Bool, detail: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text(icon)
                    .font(.title2)

                Text(title)
                    .font(.headline)

                Spacer()

                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.mint)
                        .font(.title3)
                } else if isCurrent {
                    ProgressView()
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.gray)
                        .font(.title3)
                }
            }

            if let detail = detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 40)
            }
        }
        .padding(.horizontal)
    }

    private func isStepCompleted(_ step: RecommendViewModel.ProgressStep) -> Bool {
        let steps: [RecommendViewModel.ProgressStep] = [.fetchingWeather, .filtering, .textSelecting, .multimodalSelecting, .done]
        guard let currentIndex = steps.firstIndex(of: viewModel.currentStep),
              let stepIndex = steps.firstIndex(of: step) else {
            return false
        }
        return currentIndex > stepIndex
    }
}
