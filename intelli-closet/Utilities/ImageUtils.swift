import UIKit

enum ImageUtils {

    static func compressImage(_ image: UIImage, maxBytes: Int = 1_000_000) -> Data? {
        var quality: CGFloat = 0.8
        while quality > 0.1 {
            if let data = image.jpegData(compressionQuality: quality),
               data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }
        return image.jpegData(compressionQuality: 0.1)
    }

    static func generateThumbnail(_ image: UIImage, size: CGFloat = 300) -> Data? {
        let targetSize = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let thumbnail = renderer.image { _ in
            let aspectWidth = size / image.size.width
            let aspectHeight = size / image.size.height
            let scale = max(aspectWidth, aspectHeight)
            let scaledSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(
                x: (size - scaledSize.width) / 2,
                y: (size - scaledSize.height) / 2
            )
            image.draw(in: CGRect(origin: origin, size: scaledSize))
        }
        return thumbnail.jpegData(compressionQuality: 0.7)
    }
}
