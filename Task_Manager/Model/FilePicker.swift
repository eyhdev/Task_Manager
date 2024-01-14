//
//  FilePicker.swift
//  Task_Manager
//
//  Created by eyh.mac on 14.01.2024.
//

import SwiftUI
import MobileCoreServices

struct FilePickerView: UIViewControllerRepresentable {
    @Binding var selectedFile: URL?

    class Coordinator: NSObject, UINavigationControllerDelegate, UIDocumentPickerDelegate {
        var parent: FilePickerView

        init(parent: FilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                parent.selectedFile = url
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        viewController.view.backgroundColor = .clear
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        let documentPicker = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        documentPicker.delegate = context.coordinator
        documentPicker.allowsMultipleSelection = false
        uiViewController.present(documentPicker, animated: true, completion: nil)
    }
}
