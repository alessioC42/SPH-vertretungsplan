//
//  ImagePickerCamera.swift
//  Runner
//
//  Created by Rajala1404 on 02.03.25.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage
    @Environment(\.presentationMode) private var presentationMode
    var sourceType: UIImagePickerController.SourceType = .camera;
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let pickerController = UIImagePickerController()
        pickerController.sourceType = .camera
        pickerController.mediaTypes = ["public.image"]
        pickerController.allowsEditing = true
        pickerController.delegate = context.coordinator
        
        return pickerController;
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // Don't touch it
    }
    
    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
        
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
