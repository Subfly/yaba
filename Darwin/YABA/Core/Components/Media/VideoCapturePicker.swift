//
//  VideoCapturePicker.swift
//  YABA
//
//  UIKit bridge for recording video via UIImagePickerController.
//

import SwiftUI
import UniformTypeIdentifiers

/// Presents the system camera UI in video mode and returns the captured movie file URL.
struct VideoCapturePicker: UIViewControllerRepresentable {
    var onDismiss: () -> Void
    var onCapture: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [UTType.movie.identifier]
        picker.cameraCaptureMode = .video
        picker.videoQuality = .typeHigh
        picker.delegate = context.coordinator
        picker.modalPresentationStyle = .fullScreen
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: VideoCapturePicker

        init(parent: VideoCapturePicker) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { parent.onDismiss() }
            if let url = info[.mediaURL] as? URL {
                parent.onCapture(url)
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.onDismiss()
        }
    }
}
