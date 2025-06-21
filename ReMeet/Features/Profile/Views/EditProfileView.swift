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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {

                    // 🔲 Grid of photos
                    ProfilePhotoGrid(images: $images, showDeleteButtons: true)

                    // ➕ Add more photos
                    Button {
                        // Automatically handled by grid
                    } label: {
                        Text("Add photos or videos")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)

                    // 👤 Name + age
                    ProfileRow(title: "Name", value: Binding(
                        get: { profile.firstName ?? "" },
                        set: { profile.firstName = $0 }
                    ))

                    ProfileRow(title: "Age", value: Binding(
                        get: { "\(profile.age ?? 18)" },
                        set: {
                            if let age = Int($0), age >= 18 {
                                profile.age = age
                            }
                        }
                    ), keyboardType: .numberPad)

                    // 🗺 City
                    ProfileRow(title: "City", value: Binding(
                        get: { profile.city ?? "" },
                        set: { profile.city = $0 }
                    ))

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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
