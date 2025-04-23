//
//  FastUserPreviewSheet.swift
//  ReMeet
//
//  Created by Artush on 17/04/2025.
//

import SwiftUI
import Supabase

struct FastUserPreviewSheet: View {
    let userId: String
        let initialFirstName: String?
        let profileImage: UIImage?
        var onClose: () -> Void

        init(userId: String, initialFirstName: String? = nil, profileImage: UIImage? = nil, onClose: @escaping () -> Void) {
            self.userId = userId
            self.initialFirstName = initialFirstName
            self.profileImage = profileImage
            self.onClose = onClose
        }

    @State private var userImage: UIImage?
    @State private var firstName: String = ""
    @State private var isVisible = false

    var body: some View {
        Group {
            HStack(spacing: 12) {
                if let image = userImage {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(firstName)
                        .font(.headline)
                        .bold()
                    Text("Tap to view profile")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            onClose()
                        }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal)
            .onAppear {
                if let image = profileImage {
                    self.userImage = image
                }
                if let name = initialFirstName {
                    self.firstName = name
                }
                if userImage == nil || firstName.isEmpty {
                    loadData()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }

            }
        }
    }

    func loadData() {
        Task {
            do {
                let profiles: [UserProfile] = try await SupabaseManager.shared.client
                    .database
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: userId)
                    .limit(1)
                    .execute()
                    .value

                guard let profile = profiles.first else { return }
                self.firstName = profile.first_name

                let photos: [UserPhoto] = try await SupabaseManager.shared.client
                    .database
                    .from("user_photos")
                    .select("url")
                    .eq("user_id", value: userId)
                    .eq("is_main", value: true)
                    .limit(1)
                    .execute()
                    .value

                if let urlStr = photos.first?.url, let url = URL(string: urlStr) {
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

private struct UserProfile: Decodable {
    let first_name: String
}

private struct UserPhoto: Decodable {
    let url: String
}

