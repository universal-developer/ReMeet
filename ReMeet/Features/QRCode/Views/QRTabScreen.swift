//
//  QRTabScreen.swift
//  ReMeet
//
//  Created by Artush on 27/04/2025.
//

// QRTabScreen.swift
// ReMeet – QR screen redesigned for show-first-share UX

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
    @State private var showScanner = false
    @State private var showFriends = false
    @State private var scannedUser: ScannedUser?

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 20) {
                Spacer()

                // QR Code Box
                VStack(spacing: 12) {
                    
                    /*(if let img = ImageCacheManager.shared.getFromRAM(forKey: "user_photo_main")
                        ?? ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                        Image(uiImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 70, height: 70)
                            .clipShape(Circle())
                    } else if let initials = profile.firstName?.prefix(1).uppercased() {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .overlay(
                                Text(initials)
                                    .font(.title2)
                                    .foregroundColor(.primary)
                            )
                    }*/

                    
                    Text(profile.firstName ?? "You")
                        .font(.title2)
                        .fontWeight(.semibold)

   
                    if let qr = myQRCodeImage {
                        ZStack {
                            Image(uiImage: qr)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(width: 220, height: 220)

                            if let img = ImageCacheManager.shared.getFromRAM(forKey: "user_photo_main")
                                ?? ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                    .shadow(radius: 3)
                            } else if let initials = profile.firstName?.prefix(1).uppercased() {
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 64, height: 64)
                                    .overlay(
                                        Text(initials)
                                            .font(.title2)
                                            .foregroundColor(.primary)
                                    )
                                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            }
                        }
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                            .padding()
                    }
                    
                    Text("Show this to connect instantly")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .onAppear {
                generateMyQRCode()
            }

            // Floating buttons
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    // Scan someone button
                    Button(action: { showScanner = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Scan")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.8))
                        .clipShape(Capsule())
                    }

                    // Friends button
                    Button(action: { showFriends = true }) {
                        Image(systemName: "person.2.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 40)
            }

            // Scanned user mini modal
            if let user = scannedUser {
                BottomProfileCard(user: user) {
                    print("💬 Message \(user.firstName)")
                }
                .transition(.move(edge: .bottom))
                .animation(.spring(), value: scannedUser)
            }
        }
        .sheet(isPresented: $showScanner) {
            QRScannerView { scannedValue in
                handleScannedQRCode(scannedValue)
                showScanner = false
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showFriends) {
            Text("Friends screen placeholder")
                .font(.title2)
                .padding()
        }
    }

    private func generateMyQRCode(forceRefresh: Bool = false) {
        // 1. Try cache first (unless forced to refresh)
        if !forceRefresh,
           let cachedQR = ImageCacheManager.shared.getFromRAM(forKey: "qr_code_main")
            ?? ImageCacheManager.shared.loadFromDisk(forKey: "qr_code_main") {
            myQRCodeImage = cachedQR
            return
        }

        // 2. Otherwise, generate and cache it
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                //let link = "https://api.remeet.app/u/\(userId)"
                let link = "https://api.remeet.app/u/5f4e7b15-220b-4414-8748-1ef1e8a324ff"

                let fg = colorScheme == .dark ? UIColor.white : UIColor.black
                let bg = colorScheme == .dark ? UIColor.black : UIColor.white

                let generatedQR = QRCodeService.generate(
                    from: link,
                    foregroundColor: fg,
                    backgroundColor: bg,
                    logo: nil // We'll overlay profile photo manually in SwiftUI
                )

                // Cache to memory and disk
                if let qr = generatedQR {
                    ImageCacheManager.shared.setToRAM(qr, forKey: "qr_code_main")
                    ImageCacheManager.shared.saveToDisk(qr, forKey: "qr_code_main")
                    await MainActor.run {
                        myQRCodeImage = qr
                    }
                } else {
                    print("❌ Failed to generate QR code image.")
                }

            } catch {
                print("❌ QR code generation failed: \(error)")
            }
        }
    }



    private func handleScannedQRCode(_ value: String) {
        print("📸 Scanned QR Code: \(value)")

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let myId = session.user.id.uuidString

                guard let scannedURL = URL(string: value),
                      let uuidString = scannedURL.pathComponents.last,
                      UUID(uuidString: uuidString) != nil else {
                    print("❌ Invalid QR format")
                    return
                }

                let friendId = uuidString

                do {
                    _ = try await SupabaseManager.shared.client.database
                        .from("friends")
                        .select("friend_id")
                        .eq("user_id", value: myId)
                        .eq("friend_id", value: friendId)
                        .single()
                        .execute()

                    let friendProfile = try await SupabaseManager.shared.client.database
                        .from("profiles")
                        .select("first_name")
                        .eq("id", value: friendId)
                        .limit(1)
                        .execute()

                    if let json = try? JSONSerialization.jsonObject(with: friendProfile.data) as? [String: Any],
                       let name = json["first_name"] as? String {
                        await MainActor.run {
                            withAnimation {
                                self.scannedUser = ScannedUser(id: friendId, firstName: name, image: nil)
                            }
                        }
                    }
                    return
                } catch {
                    print("👥 Friend not found, inserting")
                }

                try await SupabaseManager.shared.client.database
                    .from("friends")
                    .insert([["user_id": myId, "friend_id": friendId]])
                    .execute()

                let friendProfile = try await SupabaseManager.shared.client.database
                    .from("profiles")
                    .select("first_name")
                    .eq("id", value: friendId)
                    .limit(1)
                    .execute()

                var name = "New Friend"
                if let json = try? JSONSerialization.jsonObject(with: friendProfile.data) as? [String: Any],
                   let parsedName = json["first_name"] as? String {
                    name = parsedName
                }

                // Fetch profile photo
                let photoResult = try await SupabaseManager.shared.client.database
                    .from("user_photos")
                    .select("url")
                    .eq("user_id", value: friendId)
                    .eq("is_main", value: true)
                    .limit(1)
                    .single()
                    .execute()

                var image: UIImage? = nil

                if let json = try? JSONSerialization.jsonObject(with: photoResult.data) as? [String: Any],
                   let urlString = json["url"] as? String,
                   let url = URL(string: urlString),
                   let data = try? Data(contentsOf: url),
                   let uiImage = UIImage(data: data) {
                    image = uiImage
                }

                await MainActor.run {
                    withAnimation {
                        self.scannedUser = ScannedUser(id: friendId, firstName: name, image: image)
                    }
                }


                let mirrorURL = URL(string: "https://qquleedmyqrpznddhsbv.functions.supabase.co/mirror_friendship")!
                var request = URLRequest(url: mirrorURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                let payload: [String: String] = ["user_id": myId, "friend_id": friendId]
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)
                let (data, response) = try await URLSession.shared.data(for: request)

                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Mirror status: \(httpResponse.statusCode)")
                    print("📨 Mirror response: \(String(data: data, encoding: .utf8) ?? "")")
                }

            } catch {
                print("❌ QR processing failed: \(error)")
            }
        }
    }
}


