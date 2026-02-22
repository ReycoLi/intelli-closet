//
//  MainTabView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            WardrobeView()
                .tabItem {
                    Label("衣橱", systemImage: "tshirt")
                }
            AddClothingView()
                .tabItem {
                    Label("添加", systemImage: "camera")
                }
            RecommendView()
                .tabItem {
                    Label("推荐", systemImage: "sparkles")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person")
                }
        }
        .tint(.mint)
    }
}
