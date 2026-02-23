import SwiftUI
import PhotosUI

struct PhotoPickerView: View {
    @Bindable var viewModel: AddClothingViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "tshirt.fill")
                .font(.system(size: 80))
                .foregroundStyle(.mint)

            Text("拍照或选择衣物")
                .font(.title2)
                .foregroundStyle(.secondary)

            Text("支持一次选择最多5张照片")
                .font(.caption)
                .foregroundStyle(.tertiary)

            VStack(spacing: 16) {
                Button {
                    viewModel.showCamera = true
                } label: {
                    Label("拍照", systemImage: "camera.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.mint)

                PhotosPicker(
                    selection: $viewModel.selectedPhotos,
                    maxSelectionCount: 5,
                    matching: .images
                ) {
                    Label("从相册选择", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.mint)
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.showCamera) {
            CameraView { image in
                Task {
                    await viewModel.handleCapturedImage(image)
                }
            }
            .ignoresSafeArea()
        }
    }
}
