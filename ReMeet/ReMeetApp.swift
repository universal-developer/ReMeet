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
                MainAppView() // If logged in, load the main app
            } else {
                NavigationView {
                    WelcomeView() // Show Welcome screen for new users
                }
            }
        }
    }
}
