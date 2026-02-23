import SwiftUI
import SwiftData

struct BatchReviewView: View {
    let viewModel: AddClothingViewModel
    let onCancel: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var currentItemID: UUID?
    @State private var savedIDs: Set<UUID> = []
    @State private var skippedIDs: Set<UUID> = []
    @State private var isDone = false

    private var reviewableItems: [AddClothingViewModel.BatchItem] {
        viewModel.batchItems.filter {
            if case .success = $0.status { return true }
            return false
        }
    }

    private var failedCount: Int {
        viewModel.batchItems.count - reviewableItems.count
    }

    private var allReviewed: Bool {
        reviewableItems.allSatisfy { savedIDs.contains($0.id) || skippedIDs.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if isDone {
                doneView
            } else if reviewableItems.isEmpty {
                noValidItemsView
            } else {
                // Progress dots
                HStack(spacing: 4) {
                    ForEach(reviewableItems) { item in
                        Circle()
                            .fill(dotColor(for: item.id))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.top, 8)

                // Swipeable edit cards
                TabView(selection: $currentItemID) {
                    ForEach(reviewableItems) { item in
                        BatchItemEditCard(
                            item: item,
                            isSaved: savedIDs.contains(item.id),
                            isSkipped: skippedIDs.contains(item.id),
                            onSave: { saveItem(item) },
                            onSkip: { skippedIDs.insert(item.id) }
                        )
                        .tag(Optional(item.id))
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom: done button when all reviewed
                if allReviewed {
                    Button {
                        isDone = true
                    } label: {
                        Text("完成（已保存\(savedIDs.count)件）")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.mint))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }

            // Failed/duplicate summary
            if failedCount > 0 && !reviewableItems.isEmpty && !isDone {
                HStack {
                    Image(systemName: "info.circle").foregroundStyle(.secondary)
                    Text("\(failedCount)张照片无法添加（重复或无效）")
                        .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.bottom, 4)
            }
        }
        .navigationTitle("批量添加")
        .onAppear {
            if currentItemID == nil {
                currentItemID = reviewableItems.first?.id
            }
        }
    }

    private func saveItem(_ item: AddClothingViewModel.BatchItem) {
        guard let photoData = ImageUtils.compressImage(item.image),
              let thumbnailData = ImageUtils.generateThumbnail(item.image) else { return }

        let clothing = ClothingItem(
            name: item.name, photo: photoData, thumbnail: thumbnailData,
            category: item.category, subcategory: item.subcategory,
            primaryColor: item.primaryColor,
            secondaryColor: item.secondaryColor.isEmpty ? nil : item.secondaryColor,
            material: item.material, warmthLevel: item.warmthLevel,
            styleTags: item.styleTags, fit: item.fit,
            itemDescription: item.itemDescription
        )
        modelContext.insert(clothing)
        savedIDs.insert(item.id)

        // Auto-advance
        if let next = reviewableItems.first(where: { !savedIDs.contains($0.id) && !skippedIDs.contains($0.id) && $0.id != item.id }) {
            withAnimation { currentItemID = next.id }
        }
    }

    private func dotColor(for id: UUID) -> Color {
        if savedIDs.contains(id) { return .green }
        if skippedIDs.contains(id) { return .gray }
        if id == currentItemID { return .mint }
        return .gray.opacity(0.3)
    }

// PLACEHOLDER_REMAINING

    private var doneView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.green)
            Text("已保存\(savedIDs.count)件衣物")
                .font(.title3)
            Button("返回") { onCancel() }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
            Spacer()
        }
    }

    private var noValidItemsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            Text("没有可添加的衣物")
                .font(.title3)
            Text("所有照片均为重复或无效")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("返回") { onCancel() }
                .buttonStyle(.borderedProminent)
                .tint(.mint)
        }
    }
}

// MARK: - Single batch item edit card

private struct BatchItemEditCard: View {
    @Bindable var item: AddClothingViewModel.BatchItem
    let isSaved: Bool
    let isSkipped: Bool
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        if isSaved {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60)).foregroundStyle(.green)
                Text("已保存").font(.title3)
                Text(item.name).foregroundStyle(.secondary)
            }
        } else if isSkipped {
            VStack(spacing: 16) {
                Image(systemName: "forward.fill")
                    .font(.system(size: 40)).foregroundStyle(.gray)
                Text("已跳过").font(.title3).foregroundStyle(.secondary)
            }
        } else {
            editForm
        }
    }

    private var editForm: some View {
        Form {
            Section {
                Image(uiImage: item.image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Section("基本信息") {
                TextField("名称", text: $item.name)
                Picker("分类", selection: $item.category) {
                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                TextField("子分类", text: $item.subcategory)
            }

            Section("外观") {
                TextField("主要颜色", text: $item.primaryColor)
                TextField("次要颜色", text: $item.secondaryColor)
                TextField("材质", text: $item.material)
                TextField("版型", text: $item.fit)
            }

            Section("保暖等级") {
                Picker("保暖等级", selection: $item.warmthLevel) {
                    ForEach(1...5, id: \.self) { level in
                        Text("\(level)").tag(level)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("风格标签") {
                if !item.styleTags.isEmpty {
                    Text(item.styleTags.joined(separator: "、"))
                } else {
                    Text("无").foregroundStyle(.secondary)
                }
            }

            Section("AI 描述") {
                Text(item.itemDescription).foregroundStyle(.secondary)
            }

            Section {
                Button { onSave() } label: {
                    Text("保存").font(.headline).frame(maxWidth: .infinity)
                }
                .tint(.mint)
                .disabled(item.name.isEmpty)

                Button("跳过", role: .destructive) { onSkip() }
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
