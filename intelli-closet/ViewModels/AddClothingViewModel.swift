import Foundation
import SwiftUI
import PhotosUI
import SwiftData
import CryptoKit

@Observable
class AddClothingViewModel {

    enum State {
        case pickPhoto
        case analyzing
        case invalidPhoto(reason: String)
        case editResult
        case batchAnalyzing
        case batchReview
    }

    // MARK: - Batch Item

    @Observable
    class BatchItem: Identifiable {
        let id = UUID()
        let image: UIImage
        var status: BatchItemStatus = .analyzing
        var name = ""
        var category: ClothingCategory = .top
        var subcategory = ""
        var primaryColor = ""
        var secondaryColor = ""
        var material = ""
        var warmthLevel = 3
        var styleTags: [String] = []
        var fit = ""
        var itemDescription = ""
        var isDuplicate = false

        init(image: UIImage) {
            self.image = image
        }
    }

    enum BatchItemStatus {
        case analyzing
        case success
        case invalid(String)
        case failed(String)
    }

    // MARK: - Single photo (camera)

    var capturedImage: UIImage?
    var showCamera = false
    var analysisResult: ClothingAnalysisResult?
    var isAnalyzing = false
    var errorMessage: String?

    // Editable fields (single mode)
    var name = ""
    var category: ClothingCategory = .top
    var subcategory = ""
    var primaryColor = ""
    var secondaryColor = ""
    var material = ""
    var warmthLevel = 3
    var styleTags: [String] = []
    var fit = ""
    var itemDescription = ""

    // MARK: - Batch photo (album)

    var selectedPhotos: [PhotosPickerItem] = []
    var batchItems: [BatchItem] = []

    var state: State = .pickPhoto

    var batchAnalyzedCount: Int {
        batchItems.filter { if case .analyzing = $0.status { return false } else { return true } }.count
    }

    var batchSuccessItems: [BatchItem] {
        batchItems.filter { if case .success = $0.status { return true } else { return false } }
    }

    // MARK: - Camera (single photo)

    @MainActor
    func handleCapturedImage(_ image: UIImage) async {
        capturedImage = image
        await analyzeSingleImage(image)
    }

    @MainActor
    private func analyzeSingleImage(_ image: UIImage) async {
        state = .analyzing
        isAnalyzing = true
        errorMessage = nil

        do {
            guard let compressedData = ImageUtils.compressImage(image) else {
                errorMessage = "图片压缩失败"
                state = .pickPhoto
                isAnalyzing = false
                return
            }

            let result = try await AliyunService.shared.analyzeClothing(imageData: compressedData)
            analysisResult = result

            if result.isValid {
                name = result.name ?? ""
                if let categoryStr = result.category {
                    category = categoryStr == "上装" ? .top : .bottom
                }
                subcategory = result.subcategory ?? ""
                primaryColor = result.primaryColor ?? ""
                secondaryColor = result.secondaryColor ?? ""
                material = result.material ?? ""
                warmthLevel = result.warmthLevel ?? 3
                styleTags = result.styleTags ?? []
                fit = result.fit ?? ""
                itemDescription = result.description ?? ""
                state = .editResult
            } else {
                state = .invalidPhoto(reason: result.invalidReason ?? "照片不符合要求")
            }
        } catch {
            errorMessage = "分析失败: \(error.localizedDescription)"
            state = .pickPhoto
        }
        isAnalyzing = false
    }

    // MARK: - Batch (album multi-select)

    @MainActor
    func handleSelectedPhotos(existingItems: [ClothingItem]) async {
        guard !selectedPhotos.isEmpty else { return }

        let existingHashes = Set(existingItems.compactMap { photoHash($0.thumbnail) })

        batchItems = []
        state = .batchAnalyzing

        // Load all images first
        var loaded: [UIImage] = []
        for item in selectedPhotos {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                loaded.append(image)
            }
        }
        selectedPhotos = []

        // Create batch items and check duplicates via thumbnail hash
        for image in loaded {
            let batchItem = BatchItem(image: image)
            if let thumbData = ImageUtils.generateThumbnail(image) {
                let hash = photoHash(thumbData)
                if existingHashes.contains(hash) {
                    batchItem.isDuplicate = true
                    batchItem.status = .invalid("该衣物已存在衣橱中")
                }
            }
            batchItems.append(batchItem)
        }

        // Analyze non-duplicate items in parallel
        await withTaskGroup(of: Void.self) { group in
            for item in batchItems where !item.isDuplicate {
                group.addTask { @MainActor in
                    await self.analyzeBatchItem(item)
                }
            }
        }

        state = .batchReview
    }

    @MainActor
    private func analyzeBatchItem(_ item: BatchItem) async {
        do {
            guard let compressed = ImageUtils.compressImage(item.image) else {
                item.status = .failed("图片压缩失败")
                return
            }
            let result = try await AliyunService.shared.analyzeClothing(imageData: compressed)
            if result.isValid {
                item.name = result.name ?? ""
                item.category = (result.category == "上装") ? .top : .bottom
                item.subcategory = result.subcategory ?? ""
                item.primaryColor = result.primaryColor ?? ""
                item.secondaryColor = result.secondaryColor ?? ""
                item.material = result.material ?? ""
                item.warmthLevel = result.warmthLevel ?? 3
                item.styleTags = result.styleTags ?? []
                item.fit = result.fit ?? ""
                item.itemDescription = result.description ?? ""
                item.status = .success
            } else {
                item.status = .invalid(result.invalidReason ?? "照片不符合要求")
            }
        } catch {
            item.status = .failed(error.localizedDescription)
        }
    }

    // MARK: - Save

    func saveClothing(modelContext: ModelContext) -> Bool {
        guard let image = capturedImage else { return false }

        guard let photoData = ImageUtils.compressImage(image),
              let thumbnailData = ImageUtils.generateThumbnail(image) else {
            errorMessage = "图片处理失败"
            return false
        }

        let item = ClothingItem(
            name: name, photo: photoData, thumbnail: thumbnailData,
            category: category, subcategory: subcategory,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor.isEmpty ? nil : secondaryColor,
            material: material, warmthLevel: warmthLevel,
            styleTags: styleTags, fit: fit, itemDescription: itemDescription
        )
        modelContext.insert(item)
        return true
    }

    // MARK: - Helpers

    private func photoHash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    func reset() {
        capturedImage = nil
        analysisResult = nil
        isAnalyzing = false
        errorMessage = nil
        showCamera = false
        selectedPhotos = []
        batchItems = []

        name = ""
        category = .top
        subcategory = ""
        primaryColor = ""
        secondaryColor = ""
        material = ""
        warmthLevel = 3
        styleTags = []
        fit = ""
        itemDescription = ""

        state = .pickPhoto
    }
}
