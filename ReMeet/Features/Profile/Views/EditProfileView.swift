//
//  EditProfileView.swift
//  ReMeet
//
//  Created by Artush on 21/06/2025.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var profile: ProfileStore
    @Binding var images: [ImageItem]

    @State private var hasChanges = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // 🔲 Grid of photos
                    ProfilePhotoGrid(images: $images, showDeleteButtons: true)
                        .onChange(of: images) { _, _ in
                            hasChanges = true
                        }

                    // 👤 Name + age
                    ProfileRow(title: "Name", value: Binding(
                        get: { profile.firstName ?? "" },
                        set: {
                            profile.firstName = $0
                            hasChanges = true
                        }
                    ))

                    ProfileRow(title: "Age", value: Binding(
                        get: { "\(profile.age ?? 18)" },
                        set: {
                            if let age = Int($0), age >= 18 {
                                profile.age = age
                                hasChanges = true
                            }
                        }
                    ), keyboardType: .numberPad)

                    // 🗺 City
                    ProfileRow(title: "City", value: Binding(
                        get: { profile.city ?? "" },
                        set: {
                            profile.city = $0
                            hasChanges = true
                        }
                    ))

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading:
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(.primary),

                trailing:
                    NavBarButton(
                        title: "Done",
                        action: { dismiss() },
                        isEnabled: hasChanges
                    )
            )
        }
    }
}

struct ProfileRow: View {
    let title: String
    @Binding var value: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Enter \(title.lowercased())", text: $value)
                .keyboardType(keyboardType)
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


#Preview {
    let store = ProfileStore.shared

    // Mock profile data
    store.firstName = "Artush"
    store.age = 18
    store.city = "Lyon"
    store.preloadedProfilePhotos = [
        ImageItem(image: UIImage(systemName: "person.fill")!, isMain: true),
        ImageItem(image: UIImage(systemName: "person.fill")!),
        ImageItem(image: UIImage(systemName: "person.fill")!)
    ]
    store.userImage = store.preloadedProfilePhotos.first?.image
    store.hasLoadedOnce = true

    return EditProfileView(
        images: .constant(store.preloadedProfilePhotos)
    )
    .environmentObject(store)
}
