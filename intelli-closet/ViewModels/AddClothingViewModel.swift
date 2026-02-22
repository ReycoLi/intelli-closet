//
//  AddClothingViewModel.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import Foundation
import SwiftUI
import PhotosUI
import SwiftData

@Observable
class AddClothingViewModel {

    enum State {
        case pickPhoto
        case analyzing
        case invalidPhoto(reason: String)
        case editResult
    }

    // Photo handling
    var selectedPhoto: PhotosPickerItem?
    var capturedImage: UIImage?
    var showCamera = false

    // Analysis
    var analysisResult: ClothingAnalysisResult?
    var isAnalyzing = false
    var errorMessage: String?

    // Editable fields
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

    var state: State = .pickPhoto

    @MainActor
    func handleSelectedPhoto() async {
        guard let selectedPhoto = selectedPhoto else { return }

        do {
            guard let data = try await selectedPhoto.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "无法加载照片"
                return
            }

            capturedImage = image
            await analyzeImage(image)
        } catch {
            errorMessage = "加载照片失败: \(error.localizedDescription)"
        }
    }

    @MainActor
    func handleCapturedImage(_ image: UIImage) async {
        capturedImage = image
        await analyzeImage(image)
    }

    @MainActor
    func analyzeImage(_ image: UIImage) async {
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
                // Populate editable fields
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

    func saveClothing(modelContext: ModelContext) -> Bool {
        guard let image = capturedImage else { return false }

        guard let photoData = ImageUtils.compressImage(image),
              let thumbnailData = ImageUtils.generateThumbnail(image) else {
            errorMessage = "图片处理失败"
            return false
        }

        let item = ClothingItem(
            name: name,
            photo: photoData,
            thumbnail: thumbnailData,
            category: category,
            subcategory: subcategory,
            primaryColor: primaryColor,
            secondaryColor: secondaryColor.isEmpty ? nil : secondaryColor,
            material: material,
            warmthLevel: warmthLevel,
            styleTags: styleTags,
            fit: fit,
            itemDescription: itemDescription
        )

        modelContext.insert(item)
        return true
    }

    func reset() {
        selectedPhoto = nil
        capturedImage = nil
        analysisResult = nil
        isAnalyzing = false
        errorMessage = nil
        showCamera = false

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
