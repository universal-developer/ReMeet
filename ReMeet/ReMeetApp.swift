import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var isSplashActive = true
    @StateObject var orchestrator = MapOrchestrator()

    var body: some Scene {
        WindowGroup {
            if isSplashActive {
                SplashScreenView(isActive: $isSplashActive)
            } else {
                if isLoggedIn {
                    MainAppView(orchestrator: orchestrator)
                } else {
                    NavigationView {
                        WelcomeView(orchestrator: orchestrator)
                    }
                }
            }
        }
    }
}
