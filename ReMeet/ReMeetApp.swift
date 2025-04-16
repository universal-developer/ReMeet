import SwiftUI
import CoreLocation

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainAppView()
            } else {
                NavigationView {
                    WelcomeView()
                }
            }
        }
    }
}
