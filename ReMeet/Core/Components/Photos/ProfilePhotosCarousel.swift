//
//  ProfileCardView.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct ProfilePhotosCarousel: View {
    let images: [ImageItem]

    var body: some View {
        GeometryReader { geo in
            if images.isEmpty {
                ZStack {
                    Color.gray.opacity(0.1)
                        .frame(width: geo.size.width, height: geo.size.height)
                    ProgressView("Loading photos…")
                }
            } else {
                TabView {
                    ForEach(images.indices, id: \.self) { index in
                        if let uiImage = images[index].image {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        } else {
                            Color.gray.opacity(0.1) // fallback block
                                .frame(width: geo.size.width, height: geo.size.height)
                        }
                    }

                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .interactive))
            }
        }
        .frame(height: 400)
        .edgesIgnoringSafeArea(.horizontal)
    }
}
