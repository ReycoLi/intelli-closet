//
//  ProfileViewModel.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI
import SwiftData
import PhotosUI

@Observable
class ProfileViewModel {
    var height: String = ""
    var weight: String = ""
    var headshotItem: PhotosPickerItem?
    var fullBodyItem: PhotosPickerItem?
    var headshotImage: UIImage?
    var fullBodyImage: UIImage?
    var isSaved = false

    func load(from profile: UserProfile?) {
        guard let profile else { return }
        height = profile.height.map { String(Int($0)) } ?? ""
        weight = profile.weight.map { String(Int($0)) } ?? ""
        if let data = profile.headshotPhoto { headshotImage = UIImage(data: data) }
        if let data = profile.fullBodyPhoto { fullBodyImage = UIImage(data: data) }
    }

    func save(profile: UserProfile, modelContext: ModelContext) {
        profile.height = Double(height)
        profile.weight = Double(weight)
        if let img = headshotImage {
            profile.headshotPhoto = ImageUtils.compressImage(img, maxBytes: 500_000)
        }
        if let img = fullBodyImage {
            profile.fullBodyPhoto = ImageUtils.compressImage(img, maxBytes: 1_000_000)
        }
        isSaved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isSaved = false
        }
    }

    func handleHeadshotPick() async {
        guard let item = headshotItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        headshotImage = image
    }

    func handleFullBodyPick() async {
        guard let item = fullBodyItem,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        fullBodyImage = image
    }
}
