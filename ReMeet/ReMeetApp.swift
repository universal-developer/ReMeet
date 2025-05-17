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
                    SplashScreenView(isActive: $isSplashActive)
                        .transition(.opacity)
                } else if !profileLoaded {
                    SplashScreenView(isActive: .constant(true))
                        .onAppear {
                            Task {
                                // Check if user is authenticated
                                guard let user = SupabaseManager.shared.client.auth.currentUser else {
                                    isLoggedIn = false
                                    profileLoaded = true
                                    return
                                }

                                let exists = await SupabaseManager.shared.checkUserExists(user.id)
                                if exists {
                                    await profileStore.loadBasicProfile()
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        profileLoaded = true
                                    }

                                    // Preload in background (non-blocking)
                                    Task.detached(priority: .utility) {
                                        await profileStore.loadEverything()
                                    }
                                } else {
                                    isLoggedIn = false
                                    try? await SupabaseManager.shared.client.auth.signOut()
                                    profileLoaded = true
                                }
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
}
