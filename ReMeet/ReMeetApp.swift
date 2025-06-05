import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var isSplashActive = true
    @State private var profileLoaded = false
    @State private var path: [OnboardingRoute] = []
    @StateObject var profileStore = ProfileStore.shared
    @StateObject var orchestrator = MapOrchestrator(profileStore: ProfileStore.shared)

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    SplashScreenView(isActive: $isSplashActive) {
                        await preloadAndAuthenticate()
                    }
                    .transition(.opacity)
                } else if !profileLoaded {
                    SplashScreenView(isActive: .constant(true)) {
                        await preloadAndAuthenticate()
                    }
                        .onAppear {
                            Task {
                                await preloadAndAuthenticate()
                            }
                        }
                } else {
                    if isLoggedIn {
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
            }
            .animation(.easeOut(duration: 0.35), value: profileLoaded)
        }
    }

    private func preloadAndAuthenticate() async {
        if let user = SupabaseManager.shared.client.auth.currentUser {
            let exists = await SupabaseManager.shared.checkUserExists(user.id)
            if exists {
                await profileStore.loadEverything()

                // ✅ Preload grid images into RAM + disk
                _ = await profileStore.loadProfileImagesGrid()

                await MainActor.run {
                    profileLoaded = true
                    isLoggedIn = true
                }
            } else {
                await MainActor.run {
                    isLoggedIn = false
                    profileLoaded = true
                }
                try? await SupabaseManager.shared.client.auth.signOut()
            }
        } else {
            await MainActor.run {
                isLoggedIn = false
                profileLoaded = true
            }
        }
    }

}
