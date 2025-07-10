//
//  FriendsListView.swift
//  ReMeet
//
//  Created by Artush on 07/07/2025.
//

import SwiftUI

struct FriendsListView: View {
    @EnvironmentObject var profile: ProfileStore
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List(profile.friends) { friend in
                HStack(spacing: 16) {
                    if let image = friend.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 48, height: 48)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(friend.firstName.prefix(1))
                                    .font(.title3)
                                    .foregroundColor(.white)
                            )
                    }

                    Text(friend.firstName)
                        .font(.headline)

                    Spacer()
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle()) // optional: makes the row tappable
                .onTapGesture {
                    // → Open chat screen in future
                }
            }
            .navigationTitle("Your Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            await profile.loadFriends()
        }
    }
}
