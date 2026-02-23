//
//  ProfileView.swift
//  intelli-closet
//
//  Created by Zhe Li on 2026/2/23.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @State private var viewModel = ProfileViewModel()
    @FocusState private var isInputFocused: Bool

    private var profile: UserProfile {
        if let existing = profiles.first {
            return existing
        } else {
            let newProfile = UserProfile()
            modelContext.insert(newProfile)
            return newProfile
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("身体信息") {
                    HStack {
                        Text("身高")
                        Spacer()
                        TextField("", text: $viewModel.height)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($isInputFocused)
                        Text("cm")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("", text: $viewModel.weight)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                            .focused($isInputFocused)
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("大头照") {
                    if let image = viewModel.headshotImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    PhotosPicker(selection: $viewModel.headshotItem, matching: .images) {
                        Label("选择照片", systemImage: "photo")
                    }
                }

                Section("全身照") {
                    if let image = viewModel.fullBodyImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    PhotosPicker(selection: $viewModel.fullBodyItem, matching: .images) {
                        Label("选择照片", systemImage: "photo")
                    }
                }

                Section {
                    Button("保存") {
                        viewModel.save(profile: profile, modelContext: modelContext)
                    }
                    .frame(maxWidth: .infinity)
                    .tint(.mint)
                }
            }
            .navigationTitle("我的")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") {
                        isInputFocused = false
                    }
                }
            }
            .onAppear {
                viewModel.load(from: profile)
            }
            .onChange(of: viewModel.headshotItem) { _, _ in
                Task {
                    await viewModel.handleHeadshotPick()
                }
            }
            .onChange(of: viewModel.fullBodyItem) { _, _ in
                Task {
                    await viewModel.handleFullBodyPick()
                }
            }
            .overlay(alignment: .top) {
                if viewModel.isSaved {
                    Text("已保存 ✓")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(Color.mint)
                        .clipShape(Capsule())
                        .padding(.top, 50)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(), value: viewModel.isSaved)
        }
    }
}
