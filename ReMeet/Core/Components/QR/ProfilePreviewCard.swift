//
//  BottomProfileCard.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct ProfilePreviewCard: View {
    let user: ScannedUser
    let primaryActionLabel: String
    var onPrimaryAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            if let image = user.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 72, height: 72)
                    .overlay(Text(user.firstName.prefix(1)).font(.title))
            }

            Text(user.firstName)
                .font(.headline)
                .padding(.bottom, 4)

            Button(action: onPrimaryAction) {
                Text(primaryActionLabel)
                    .font(.subheadline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(radius: 10)
    }
}
