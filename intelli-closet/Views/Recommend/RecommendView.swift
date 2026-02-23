import SwiftUI
import SwiftData

struct RecommendView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [ClothingItem]
    @State private var viewModel = RecommendViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.currentStep {
                case .idle:
                    OccasionPickerView(viewModel: viewModel) {
                        Task {
                            await viewModel.startRecommendation(allItems: allItems)
                        }
                    }

                case .fetchingWeather, .filtering, .preSelecting, .recommending:
                    RecommendProgressView(viewModel: viewModel)

                case .done:
                    OutfitResultView(outfits: viewModel.outfits) {
                        viewModel.reset()
                    }

                case .error:
                    errorView
                }
            }
            .navigationTitle("智能推荐")
            .alert("定位失败", isPresented: $viewModel.showCityInput) {
                TextField("输入城市名称", text: $viewModel.cityInput)
                Button("确定") {
                    Task {
                        await viewModel.retryWithCity(allItems: allItems)
                    }
                }
                Button("手动输入天气") {
                    viewModel.showCityInput = false
                    viewModel.showManualWeather = true
                }
                Button("取消", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text("无法获取当前位置，请输入城市名称或手动输入天气")
            }
            .alert("获取天气失败", isPresented: $viewModel.showManualWeather) {
                TextField("天气描述（如：晴天、多云）", text: $viewModel.manualWeatherInput)
                Button("确定") {
                    Task {
                        await viewModel.retryWithManualWeather(allItems: allItems)
                    }
                }
                Button("取消", role: .cancel) {
                    viewModel.reset()
                }
            } message: {
                Text("请手动输入天气描述")
            }
        }
    }

    private var errorView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundStyle(.red)

                Text("推荐失败")
                    .font(.title2)
                    .fontWeight(.bold)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Filter explanation
                if !viewModel.filterSummary.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("筛选详情", systemImage: "line.3.horizontal.decrease.circle")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text(viewModel.filterSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if !viewModel.filteredOutDetails.isEmpty {
                            Divider()
                            Text("被过滤的衣物：")
                                .font(.caption)
                                .fontWeight(.medium)
                            ForEach(viewModel.filteredOutDetails, id: \.self) { detail in
                                Text("· \(detail)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    .padding(.horizontal)
                }

                Button {
                    viewModel.reset()
                } label: {
                    Text("重试")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.mint)
                        )
                        .foregroundStyle(.white)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}
