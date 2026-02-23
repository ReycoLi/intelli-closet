import SwiftUI

struct RecommendProgressView: View {
    let viewModel: RecommendViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Step 1: Fetching Weather
            stepRow(
                icon: "cloud.sun",
                title: "获取天气信息",
                isCompleted: isStepCompleted(.fetchingWeather),
                isCurrent: viewModel.currentStep == .fetchingWeather,
                detail: isStepCompleted(.fetchingWeather) ? viewModel.weatherInfo?.summary : nil
            )

            // Step 2: Filtering
            stepRow(
                icon: "line.3.horizontal.decrease.circle",
                title: "筛选候选衣物",
                isCompleted: isStepCompleted(.filtering),
                isCurrent: viewModel.currentStep == .filtering,
                detail: isStepCompleted(.filtering) ? "上装\(viewModel.topCount)件 / 下装\(viewModel.bottomCount)件" : nil
            )

            // Step 3: Pre-selecting (only shown in two-stage)
            if viewModel.currentStep == .preSelecting || isStepCompleted(.preSelecting) {
                stepRow(
                    icon: "text.magnifyingglass",
                    title: "智能预筛选",
                    isCompleted: isStepCompleted(.preSelecting),
                    isCurrent: viewModel.currentStep == .preSelecting,
                    detail: nil
                )
            }

            // Streamed text
            if !viewModel.streamedText.isEmpty &&
                (viewModel.currentStep == .preSelecting || viewModel.currentStep == .recommending) {
                Divider()
                    .padding(.horizontal)

                ScrollView {
                    Text(viewModel.streamedText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
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
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isCurrent ? .mint : isCompleted ? .mint : .gray)
                    .frame(width: 30)

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
                    .padding(.leading, 42)
            }
        }
        .padding(.horizontal)
    }

    private func isStepCompleted(_ step: RecommendViewModel.ProgressStep) -> Bool {
        let steps: [RecommendViewModel.ProgressStep] = [.fetchingWeather, .filtering, .preSelecting, .recommending, .done]
        guard let currentIndex = steps.firstIndex(of: viewModel.currentStep),
              let stepIndex = steps.firstIndex(of: step) else {
            return false
        }
        return currentIndex > stepIndex
    }
}