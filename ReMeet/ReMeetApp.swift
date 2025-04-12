import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    init() {
        // TEMPORARY: Reset login state for testing
        UserDefaults.standard.set(false, forKey: "isLoggedIn")
    }

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                HomeView() // ← renamed from HomeView
            } else {
                NavigationView {
                    WelcomeView()
                }
            }
        }
    }
}
