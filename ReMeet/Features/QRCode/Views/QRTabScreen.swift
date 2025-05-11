//
//  QRTabScreen.swift
//  ReMeet
//
//  Created by Artush on 27/04/2025.
//

import SwiftUI
import QRCode

struct QRTabScreen: View {
    @State private var selectedTab: Tab = .myCode
    @State private var myQRCodeImage: UIImage?
    @EnvironmentObject var profile: ProfileStore
    @Environment(\.colorScheme) var colorScheme

    enum Tab {
        case scan
        case myCode
    }

    var body: some View {
        VStack(spacing: 0) {
            topTabBar

            Divider()

            if selectedTab == .scan {
                QRScannerView { scannedValue in
                    handleScannedQRCode(scannedValue)
                }
            } else {
                myQRCodeCard
                    .onChange(of: colorScheme) { _ in
                        generateMyQRCode()
                    }
                    .onAppear {
                        generateMyQRCode()
                    }
            }

            Spacer()
        }
        .navigationTitle("QR Code")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var topTabBar: some View {
        HStack {
            Button(action: { withAnimation { selectedTab = .scan } }) {
                Text("Scan")
                    .fontWeight(selectedTab == .scan ? .bold : .regular)
                    .foregroundColor(selectedTab == .scan ? .primary : .gray)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == .scan ? tabBackground : Color.clear)
                    .cornerRadius(10)
            }

            Button(action: { withAnimation { selectedTab = .myCode } }) {
                Text("My QR Code")
                    .foregroundColor(selectedTab == .myCode ? .primary : .gray)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == .myCode ? tabBackground : Color.clear)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var tabBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.1) : Color.primary.opacity(0.1)
    }

    private var myQRCodeCard: some View {
        VStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(colorScheme == .dark ? Color(.secondarySystemBackground) : Color.white)
                    .frame(width: 320, height: 450)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                VStack(spacing: 0) {
                    Text(profile.firstName ?? "You")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 15)

                    Text("ReMeet contact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                        .padding(.bottom, 24)

                    if let qr = myQRCodeImage {
                        Image(uiImage: qr)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 220, height: 220)
                            .padding(.bottom, 30)
                    } else {
                        ProgressView()
                            .frame(width: 220, height: 220)
                            .padding(.bottom, 30)
                    }
                }
            }
            .overlay(
                profileImage
                    .offset(y: -225)
            )

            Spacer()
        }
    }

    private var profileImage: some View {
        ZStack {
            Circle()
                .fill(colorScheme == .dark ? Color(.systemBackground) : Color.white)
                .frame(width: 76, height: 76)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)

            if let image = profile.userImage {
                Image(uiImage: image)
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
            }
        }
    }

    private func generateMyQRCode() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                let link = "https://api.remeet.app/u/\(userId)"
                //let link = "https://api.remeet.app/u/5f4e7b15-220b-4414-8748-1ef1e8a324ff"

                print("🔗 QR code link: \(link)")

                let fg = colorScheme == .dark ? UIColor.white : UIColor.black
                let bg = colorScheme == .dark ? UIColor.black : UIColor.white

                myQRCodeImage = QRCodeService.generate(
                    from: link,
                    foregroundColor: fg,
                    backgroundColor: bg,
                    logo: UIImage(named: "Logo")
                )
            } catch {
                print("❌ Failed to get user session for QR code generation: \(error)")
            }
        }
    }

    private func handleScannedQRCode(_ value: String) {
        print("📸 Scanned QR Code: \(value)")

        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let myId = session.user.id.uuidString

                // 1. Extract UUID from scanned QR code link
                guard let scannedURL = URL(string: value),
                      let uuidString = scannedURL.pathComponents.last,
                      UUID(uuidString: uuidString) != nil else {
                    print("❌ Invalid QR code format or UUID.")
                    return
                }

                let friendId = uuidString

                // 2. Check if friendship already exists
                do {
                    _ = try await SupabaseManager.shared.client.database
                        .from("friends")
                        .select("friend_id")
                        .eq("user_id", value: myId)
                        .eq("friend_id", value: friendId)
                        .single()
                        .execute()

                    // If this succeeds, friend already exists
                    print("⚠️ Friend \(friendId) already added.")

                    // Optional: fetch first name
                    do {
                        let friendProfile = try await SupabaseManager.shared.client.database
                            .from("profiles")
                            .select("first_name")
                            .eq("id", value: friendId)
                            .limit(1)
                            .execute()

                        if let json = try? JSONSerialization.jsonObject(with: friendProfile.data) as? [String: Any],
                           let name = json["first_name"] as? String {
                            print("👤 Already connected with: \(name)")
                        } else {
                            print("👤 Already connected with this person.")
                        }
                    } catch {
                        print("👤 Already connected, but couldn't fetch name: \(error)")
                    }

                    return // 💥 without this, you'd still insert again
                } catch {
                    print("🔎 No existing friendship found. Proceeding to insert.")
                    // This is expected when the friend isn't found
                }

                // 3. Insert A → B
                try await SupabaseManager.shared.client.database
                    .from("friends")
                    .insert([
                        ["user_id": myId, "friend_id": friendId]
                    ])
                    .execute()

                print("✅ Added friend \(friendId) for user \(myId)")

                // 4. Trigger mirror insert via Edge Function
                let mirrorURL = URL(string: "https://qquleedmyqrpznddhsbv.functions.supabase.co/mirror_friendship")!
                var request = URLRequest(url: mirrorURL)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                let payload: [String: String] = [
                    "user_id": myId,
                    "friend_id": friendId
                ]
                request.httpBody = try? JSONSerialization.data(withJSONObject: payload)

                let (data, response) = try await URLSession.shared.data(for: request)
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 Mirror function status: \(httpResponse.statusCode)")
                    if let responseText = String(data: data, encoding: .utf8) {
                        print("📨 Mirror response: \(responseText)")
                    }
                }

            } catch {
                print("❌ Failed to add friend or call mirror: \(error)")
            }
        }
    }




}
 
