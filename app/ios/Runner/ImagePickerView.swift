//
//  ImagePickerView.swift
//  Runner
//
//  Created by Rajala1404 on 02.03.25.
//

import SwiftUI

struct ImagePickerView: View {
    @State var selectedImage = UIImage()
    @State var selectImage = true
    
    var body: some View {
        VStack {
            Image(uiImage: selectedImage)
        }.sheet(isPresented: $selectImage) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
    }
}
