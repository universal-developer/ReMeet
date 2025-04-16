import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            //MainAppView()
            if isLoggedIn {
                MainAppView() // ← renamed from HomeView
            } else {
                NavigationView {
                    WelcomeView()
                }
            }
        }
    }
}
