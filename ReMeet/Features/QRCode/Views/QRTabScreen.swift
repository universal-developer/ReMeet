//
//  QRTabScreen.swift
//  ReMeet
//
//  Created by Artush on 27/04/2025.
//

import SwiftUI

struct QRTabScreen: View {
    @State private var selectedTab: Tab = .myCode
    @State private var myQRCodeImage: UIImage?

    var orchestrator: MapOrchestrator

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
                    .fontWeight(selectedTab == .myCode ? .bold : .regular)
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
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(radius: 5)

                VStack(spacing: 16) {
                    Spacer().frame(height: 40)

                    // Profile
                    if let image = orchestrator.locationController.userImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 3))
                            .background(Circle().fill(Color.white))
                            .offset(y: -60)
                    } else if let initials = orchestrator.locationController.initials {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .overlay(
                                Text(initials)
                                    .font(.title2)
                                    .foregroundColor(.black)
                            )
                            .frame(width: 80, height: 80)
                            .background(Circle().fill(Color.white))
                            .offset(y: -60)
                    }

                    // Username
                    if let name = orchestrator.locationController.firstName {
                        Text(name)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }

                    Text("ReMeet Profile")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    if let qr = myQRCodeImage {
                        Image(uiImage: qr)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding(.top, 10)
                    } else {
                        ProgressView()
                            .onAppear(perform: generateMyQRCode)
                            .padding()
                    }

                    Spacer()
                }
                .padding()
            }
            .padding(.horizontal, 30)

            Spacer()

            Text("Your QR code is private. Only share with people you meet.")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 10)

            Spacer()
        }
    }

    private func generateMyQRCode() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                let userId = session.user.id.uuidString
                myQRCodeImage = QRCodeGenerator.generateQRCode(from: userId)
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
