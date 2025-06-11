//
//  QRTabScreen.swift
//  ReMeet
//
//  Created by Artush on 27/04/2025.
//

import SwiftUI
import QRCode

struct ScannedUser: Identifiable, Equatable {
    let id: String
    let firstName: String
    let image: UIImage?

    static func == (lhs: ScannedUser, rhs: ScannedUser) -> Bool {
        lhs.id == rhs.id && lhs.firstName == rhs.firstName
    }
}

struct QRTabScreen: View {
    @EnvironmentObject var profile: ProfileStore
    @Environment(\.colorScheme) var colorScheme
    @State private var myQRCodeImage: UIImage?
    @State private var myUserId: String = ""
    @State private var showScanner = false
    @State private var showFriends = false
    @State private var scannedUser: ScannedUser? = nil

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("My Code")
                        .font(.title3)
                        .fontWeight(.semibold)
                    Text("Others can scan this to add you")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                .padding(.horizontal)

                Spacer()

                VStack(spacing: 12) {
                    if let qr = myQRCodeImage {
                        ZStack {
                            Image(uiImage: qr)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 220, height: 220)

                            if let image = profile.userImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle().stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    )
                                    .shadow(radius: 5)
                            } else if let initials = profile.firstName?.prefix(1).uppercased() {
                                Text(initials)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                    .frame(width: 100, height: 100)
                                    .background(Color.gray.opacity(0.3))
                                    .clipShape(Circle())
                            }

                        }
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                            .padding()
                    }

                    Text(profile.firstName ?? "You")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Show this to connect instantly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if !myUserId.isEmpty {
                        VStack(spacing: 2) {
                            Text("Your ID: \(myUserId)")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text("https://api.remeet.app/u/\(myUserId)")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 8)
                    }
                }

                Spacer()

                HStack(spacing: 32) {
                    VStack(spacing: 8) {
                        Button(action: { showScanner = true }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Text("Scan QR")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }

                    VStack(spacing: 8) {
                        Button(action: { showFriends = true }) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.primary)
                                .frame(width: 60, height: 60)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        Text("Friends")
                            .font(.footnote)
                            .foregroundColor(.primary)
                    }
                }
                .padding(.bottom, 32)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                    profile.userImage = refreshed
                }
            }
            .onAppear {
                generateMyQRCode()

                if profile.userImage == nil, let main = profile.preloadedProfilePhotos.first(where: { $0.isMain })?.image {
                    profile.userImage = main
                }
                
                if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                       profile.userImage = refreshed
                   }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ZStack(alignment: .topLeading) {
                QRScannerView { scannedValue in
                    handleScannedQRCode(scannedValue)
                }
                .ignoresSafeArea()

                Button(action: { showScanner = false }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .padding(16)
                }

                if let user = scannedUser {
                    VStack(spacing: 16) {
                        if let image = user.image {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 80, height: 80)
                                .overlay(Text(user.firstName.prefix(1)))
                        }

                        Text("Add \(user.firstName)?")
                            .font(.headline)
                            .multilineTextAlignment(.center)

                        HStack(spacing: 16) {
                            Button(action: { confirmFriendAdd(user) }) {
                                Text("Add")
                                    .fontWeight(.medium)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button(action: { scannedUser = nil }) {
                                Text("Cancel")
                                    .fontWeight(.medium)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gray.opacity(0.2))
                                    .foregroundColor(.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
                        if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                            profile.userImage = refreshed
                        }
                    }
                    .padding()
                    .frame(maxWidth: 280)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 12)
                    .transition(.scale)
                    .animation(.spring(), value: scannedUser)
                }
            }
        }
        .sheet(isPresented: $showFriends) {
            Text("Friends screen placeholder")
                .font(.title2)
                .padding()
        }
    }
    private func generateMyQRCode(forceRefresh: Bool = false) {
        if !forceRefresh,
              let cached = ImageCacheManager.shared.getFromRAM(forKey: "qr_code_main") ??
                           ImageCacheManager.shared.loadFromDisk(forKey: "qr_code_main") {
               myQRCodeImage = cached
               return
           }

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                myUserId = userId
                let link = "https://api.remeet.app/u/\(userId)"

                let fg = colorScheme == .dark ? UIColor.white : UIColor.black
                let bg = colorScheme == .dark ? UIColor.black : UIColor.white

                if let qr = QRCodeService.generate(from: link, foregroundColor: fg, backgroundColor: bg) {
                    ImageCacheManager.shared.setToRAM(qr, forKey: "qr_code_main")
                    ImageCacheManager.shared.saveToDisk(qr, forKey: "qr_code_main")
                    await MainActor.run { myQRCodeImage = qr }
                }
            } catch {
                print("❌ QR generation error: \(error)")
            }
        }
    }


    private func handleScannedQRCode(_ value: String) {
        print("📸 Scanned QR Code: \(value)")

        Task {
            guard let scannedURL = URL(string: value),
                  let uuidString = scannedURL.pathComponents.last,
                  UUID(uuidString: uuidString) != nil else {
                print("❌ Invalid QR format")
                return
            }

            let friendId = uuidString
            if let minimal = await profile.fetchMinimalUser(userId: friendId) {
                await MainActor.run {
                    withAnimation(.spring()) {
                        scannedUser = ScannedUser(id: minimal.id, firstName: minimal.firstName, image: minimal.image)
                    }
                }
            }
        }
    }



    private func confirmFriendAdd(_ user: ScannedUser) {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let myId = session.user.id.uuidString
                try await profile.confirmFriendAdd(myId: myId, friendId: user.id)

                await MainActor.run {
                    withAnimation(.spring()) {
                        scannedUser = nil
                    }
                }
            } catch {
                print("❌ Confirm friend add failed: \(error)")
            }
        }
    }

}

