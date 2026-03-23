//
//  PhotoPicker.swift
//  MiniMate
//
//  Created by Garrett Butchko on 5/5/25.
//


import SwiftUI
import PhotosUI

/// A simple wrapper around PHPickerViewController
struct PhotoPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first?.itemProvider,
                  item.canLoadObject(ofClass: UIImage.self)
            else { return }
            item.loadObject(ofClass: UIImage.self) { img, _ in
                DispatchQueue.main.async {
                    self.parent.image = img as? UIImage
                }
            }
        }
    }
}
