//
//  intelli_closetApp.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/22.
//

import SwiftUI
import SwiftData

@main
struct intelli_closetApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [ClothingItem.self, UserProfile.self])
    }
}
