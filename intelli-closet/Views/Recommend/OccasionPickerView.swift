import SwiftUI

struct OccasionPickerView: View {
    @Bindable var viewModel: RecommendViewModel
    let onStart: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(.mint)

            // Title
            Text("今天穿什么？")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Subtitle
            Text("选择出门目的")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Preset occasions
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.presetOccasions, id: \.self) { preset in
                    Button {
                        viewModel.occasion = preset
                        viewModel.customOccasion = ""
                    } label: {
                        Text(preset)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.occasion == preset ? Color.mint.opacity(0.2) : Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(viewModel.occasion == preset ? Color.mint : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)

            // Custom occasion
            Button {
                viewModel.occasion = "自定义"
            } label: {
                Text("自定义")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.occasion == "自定义" ? Color.mint.opacity(0.2) : Color.gray.opacity(0.1))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.occasion == "自定义" ? Color.mint : Color.clear, lineWidth: 2)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)

            if viewModel.occasion == "自定义" {
                TextField("输入场合", text: $viewModel.customOccasion)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
            }

            // Outfit count stepper
            HStack {
                Text("推荐套数")
                    .foregroundStyle(.secondary)
                Spacer()
                Stepper("\(viewModel.outfitCount)", value: $viewModel.outfitCount, in: 1...3)
            }
            .padding(.horizontal)

            // Start button
            Button {
                onStart()
            } label: {
                Text("开始推荐")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canStart ? Color.mint : Color.gray)
                    )
                    .foregroundStyle(.white)
            }
            .disabled(!canStart)
            .padding(.horizontal)

            Spacer()
        }
    }

    private var canStart: Bool {
        if viewModel.occasion == "自定义" {
            return !viewModel.customOccasion.isEmpty
        }
        return !viewModel.occasion.isEmpty
    }
}
