import SwiftUI

struct RecommendProgressView: View {
    let viewModel: RecommendViewModel
    @State private var tipIndex: Int = 0
    @State private var pulse: Bool = false

    private let tips: [(icon: String, text: String)] = [
        ("paintpalette", "正在分析颜色搭配…"),
        ("sparkles", "考虑风格协调性…"),
        ("thermometer.medium", "结合天气选择面料…"),
        ("mappin.circle", "评估场合适配度…"),
        ("arrow.triangle.2.circlepath", "对比不同组合方案…"),
    ]

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
                detail: isStepCompleted(.filtering) ? "上装\(viewModel.topCount)件 / 下装\(viewModel.bottomCount)件（过滤\(viewModel.filteredOutDetails.count)件）" : nil
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

            // Step 4: Recommending
            if viewModel.currentStep == .recommending || isStepCompleted(.recommending) {
                stepRow(
                    icon: "wand.and.stars",
                    title: "生成搭配方案",
                    isCompleted: isStepCompleted(.recommending),
                    isCurrent: viewModel.currentStep == .recommending,
                    detail: nil
                )
            }

            // Animated thinking tips (replaces raw JSON)
            if viewModel.currentStep == .preSelecting || viewModel.currentStep == .recommending {
                HStack(spacing: 10) {
                    Image(systemName: tips[tipIndex].icon)
                        .font(.title3)
                        .foregroundStyle(.mint)
                        .symbolEffect(.pulse, options: .repeating)
                    Text(tips[tipIndex].text)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.mint.opacity(0.1))
                )
                .scaleEffect(pulse ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulse)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.4), value: tipIndex)
                .onAppear {
                    pulse = true
                    startTipRotation()
                }
            }

            Spacer()
        }
        .padding()
    }

    private func startTipRotation() {
        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation {
                tipIndex = (tipIndex + 1) % tips.count
            }
        }
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