//
//  ProfileView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var profile: ProfileStore
    
    var body: some View {
        VStack(spacing: 20) {
            if profile.isLoading {
                ProgressView("Loading profile...")
            } else if let error = profile.errorMessage {
                Text("Error: \(error)").foregroundColor(.red)
            } else {
                if let name = profile.firstName {
                    Text(name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                if let age = profile.age {
                    Text("Age: \(age)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }

                if let urlString = profile.profilePhotoUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                        case .failure:
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .resizable()
                                .frame(width: 120, height: 120)
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            }

            Button("Reload Profile") {
                Task {
                    await profile.load()
                }
            }
            .padding(.top, 10)

            Spacer()
        }
        .padding()
        .onAppear {
            if profile.firstName == nil {
                Task {
                    await profile.load()
                }
            }
        }
    }
}
