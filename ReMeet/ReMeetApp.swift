//
//  ReMeetApp.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var isSplashActive = true
    @State private var path: [OnboardingRoute] = []
    @StateObject var profileStore = ProfileStore.shared
    @StateObject var orchestrator = MapOrchestrator(profileStore: ProfileStore.shared)

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    SplashScreenView(
                        onLoadComplete: {
                            await preloadAndAuthenticate()
                        },
                        isActive: $isSplashActive
                    )
                    .environmentObject(profileStore)
                    .transition(.opacity)

                } else if isLoggedIn {
                    MainAppView(orchestrator: orchestrator)
                        .environmentObject(profileStore)
                        .transition(.opacity)

                } else {
                    NavigationStack {
                        WelcomeView(orchestrator: orchestrator, path: $path)
                    }
                    .environmentObject(profileStore)
                    .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.35), value: isSplashActive)
        }
    }

    private func preloadAndAuthenticate() async {
        if let user = SupabaseManager.shared.client.auth.currentUser {
            let exists = await SupabaseManager.shared.checkUserExists(user.id)
            if exists {
                await profileStore.loadProfileAndPhotos()
                await MainActor.run {
                    isLoggedIn = true
                    isSplashActive = false
                }
            } else {
                try? await SupabaseManager.shared.client.auth.signOut()
                await MainActor.run {
                    isLoggedIn = false
                    isSplashActive = false
                }
            }
        } else {
            await MainActor.run {
                isLoggedIn = false
                isSplashActive = false
            }
        }
    }
}
