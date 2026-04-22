import SwiftUI
import PhotosUI

struct AvatarPickerRepresentable: UIViewControllerRepresentable {
    var onImageSelected: (UIImage) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onImageSelected: onImageSelected) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onImageSelected: (UIImage) -> Void
        init(onImageSelected: @escaping (UIImage) -> Void) { self.onImageSelected = onImageSelected }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async { self?.onImageSelected(image) }
                }
            }
        }
    }
}

extension UIImage {
    func resizedAndCropped(to size: CGFloat) -> UIImage {
        let side = min(self.size.width, self.size.height)
        let scale = size / side
        let newWidth = self.size.width * scale
        let newHeight = self.size.height * scale
        let originX = (size - newWidth) / 2
        let originY = (size - newHeight) / 2
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { _ in
            self.draw(in: CGRect(x: originX, y: originY, width: newWidth, height: newHeight))
        }
    }
}
