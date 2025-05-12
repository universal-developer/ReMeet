//
//  PhotosEditorView.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct PhotoEditorView: View {
    @Binding var imageItems: [ImageItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit Your Photos")
                    .font(.headline)

                ImageGrid(images: $imageItems)
                Spacer()
            }
            .navigationTitle("Modify Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // optionally upload to Supabase here
                        dismiss()
                    }
                }
            }
            .padding(.top)
        }
    }
}
