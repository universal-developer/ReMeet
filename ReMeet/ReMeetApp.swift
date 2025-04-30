import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var isSplashActive = true
    @State private var profileLoaded = false
    @StateObject var profileStore = ProfileStore.shared
    @StateObject var orchestrator = MapOrchestrator(profileStore: ProfileStore.shared)

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashActive {
                    SplashScreenView(isActive: $isSplashActive)
                        .transition(.opacity)
                } else if !profileLoaded {
                    Color(.systemBackground)
                        .ignoresSafeArea()
                    ProgressView("Loading profile…")
                        .transition(.opacity)
                        .onAppear {
                            Task {
                                await profileStore.load()
                                withAnimation(.easeOut(duration: 0.4)) {
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
                        NavigationView {
                            WelcomeView(orchestrator: orchestrator)
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
