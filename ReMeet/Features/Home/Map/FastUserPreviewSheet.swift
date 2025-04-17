//
//  FastUserPreviewSheet.swift
//  ReMeet
//
//  Created by Artush on 17/04/2025.
//

import SwiftUI

struct FastUserPreviewCard: View {
    let userId: String
    @State private var userImage: UIImage?
    @State private var firstName: String = ""

    var body: some View {
        HStack(spacing: 12) {
            if let image = userImage {
                Image(uiImage: image)
                    .resizable()
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 48, height: 48)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(firstName)
                    .font(.headline)
                    .bold()
                Text("Tap to view profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: {
                // Open chat or profile
            }) {
                Image(systemName: "ellipsis")
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
        .onAppear(perform: loadData)
    }

    func loadData() {
        Task {
            do {
                let profiles: [MapController.UserProfile] = try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                guard let profile = profiles.first else { return }
                self.firstName = profile.first_name

                let photos: [MapController.UserPhoto] = try await SupabaseManager.shared.client
                    .database
                    .from("user_photos")
                    .select("url")
                    .eq("user_id", value: userId)
                    .eq("is_main", value: true)
                    .limit(1)
                    .execute()
                    .value

                if let urlStr = photos.first?.url,
                   let url = URL(string: urlStr) {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    if let img = UIImage(data: data) {
                        self.userImage = img
                    }
                }
            } catch {
                print("❌ Failed to load user preview: \(error)")
            }
        }
    }
}
