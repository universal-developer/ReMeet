//
//  PhotoGridView.swift
//  ReMeet
//
//  Created by Artush on 19/05/2025.
//

import SwiftUI

struct PhotoGridView: View {
    let images: [ImageItem]
    let onPlaceholderTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos and videos")
                .font(.headline)
                .padding(.horizontal)

            GeometryReader { geo in
                let width = geo.size.width
                let largeImageSize = width * 0.58
                let smallImageSize = width * 0.35

                VStack(spacing: 12) {
                    HStack(alignment: .top, spacing: 12) {
                        if images.indices.contains(0) {
                            ZStack(alignment: .bottomLeading) {
                                Image(uiImage: images[0].image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: largeImageSize, height: largeImageSize)
                                    .clipped()
                                    .cornerRadius(16)

                                Text("Main")
                                    .font(.caption2)
                                    .padding(6)
                                    .background(Color.black.opacity(0.6))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                                    .padding(8)
                            }
                        } else {
                            placeholderCell(size: largeImageSize)
                        }

                        VStack(spacing: 12) {
                            ForEach(1...2, id: \.self) { i in
                                if images.indices.contains(i) {
                                    Image(uiImage: images[i].image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: (width - 48) / 3, height: (width - 48) / 3)
                                        .clipped()
                                        .cornerRadius(16)
                                } else {
                                    Button(action: onPlaceholderTapped) {
                                        placeholderCell(size: (width - 48) / 3)
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 12) {
                        ForEach(3...5, id: \.self) { i in
                            if images.indices.contains(i) {
                                Image(uiImage: images[i].image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: (width - 48) / 3, height: (width - 48) / 3)
                                    .clipped()
                                    .cornerRadius(16)
                            } else {
                                Button(action: onPlaceholderTapped) {
                                    placeholderCell(size: (width - 48) / 3)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: UIScreen.main.bounds.width * 0.95)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func placeholderCell(size: CGFloat, width: CGFloat? = nil) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .stroke(style: StrokeStyle(lineWidth: 1, dash: [5]))
                .frame(width: width ?? size, height: size)
                .foregroundColor(.gray)

            Image(systemName: "plus")
                .font(.title2)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    PhotoGridView(images: [], onPlaceholderTapped: {})
        .previewLayout(.sizeThatFits)
        .padding()
}
