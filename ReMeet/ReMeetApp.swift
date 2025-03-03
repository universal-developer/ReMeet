import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainAppView() // If logged in, load the main app
            } else {
                WelcomeView() // Show Welcome screen for new users
            }
        }
    }
}
