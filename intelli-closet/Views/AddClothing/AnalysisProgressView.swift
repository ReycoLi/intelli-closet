//
//  AnalysisProgressView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI

struct AnalysisProgressView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("正在分析衣物...")
                .font(.title3)
                .fontWeight(.medium)

            Text("AI 正在识别衣物属性")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
