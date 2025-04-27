import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject var orchestrator = MapOrchestrator()


    var body: some Scene {
        WindowGroup {
            //MainAppView()
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
