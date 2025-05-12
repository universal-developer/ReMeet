//
//  BottomProfileCard.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct BottomProfileCard: View {
    let user: ScannedUser
    var onMessage: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            if let image = user.image {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .overlay(Text(user.firstName.prefix(1)).font(.title))
            }

            Text(user.firstName)
                .font(.headline)

            Button(action: onMessage) {
                Text("Send a message")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .padding(.horizontal)
        .shadow(radius: 10)
    }
}

#Preview {
    BottomProfileCard(
        user: ScannedUser(
            id: "demo-user-id",
            firstName: "Alex",
            image: nil
        ),
        onMessage: { print("Tapped send message") }
    )
}

