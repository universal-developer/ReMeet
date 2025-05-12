//
//  ProfileCardView.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct ProfilePhotosCarousel: View {
    @EnvironmentObject var profile: ProfileStore

    var body: some View {
        GeometryReader { geo in
            TabView {
                ForEach(profile.profilePhotoURLs, id: \.self) { urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray
                                .opacity(0.1)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .overlay(ProgressView())
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geo.size.width, height: geo.size.height)
                                .clipped()
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    // ❌ NO padding here!
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .interactive))
        }
        .frame(height: 400)
        .edgesIgnoringSafeArea(.horizontal) // ✅ edge-to-edge width
    }
}
