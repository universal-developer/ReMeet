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
                    .background(selectedTab == .scan ? Color.primary.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
            }

            Button(action: { withAnimation { selectedTab = .myCode } }) {
                Text("My QR Code")
                    .foregroundColor(selectedTab == .myCode ? .primary : .gray)
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(selectedTab == .myCode ? Color.primary.opacity(0.1) : Color.clear)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var myQRCodeCard: some View {
        VStack {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .frame(width: 320, height: 450)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)

                VStack(spacing: 0) {
                    Text(profile.firstName ?? "You")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 15)

                    Text("ReMeet contact")
                        .font(.subheadline)
                        .foregroundColor(.gray)
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
                            .onAppear(perform: generateMyQRCode)
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
                .fill(Color.white)
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
                            .foregroundColor(.black)
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

                print("🔗 QR code link: \(link)")

                myQRCodeImage = QRCodeService.generate(
                    from: link,
                    foregroundColor: .black,
                    backgroundColor: .white,
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
                let friendId = value

                try await SupabaseManager.shared.client.database
                    .from("friends")
                    .insert([
                        ["user_id": myId, "friend_id": friendId],
                        ["user_id": friendId, "friend_id": myId]
                    ])
                    .execute()

                print("✅ Successfully added friend \(friendId)!")
            } catch {
                print("❌ Failed to add friend: \(error)")
            }
        }
    }
}
