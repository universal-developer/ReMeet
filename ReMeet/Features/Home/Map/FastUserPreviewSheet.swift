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
    var onClose: () -> Void

    @State private var userImage: UIImage?
    @State private var firstName: String = ""

    var body: some View {
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
                onClose()
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
