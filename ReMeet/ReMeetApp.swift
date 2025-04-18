import SwiftUI

@main
struct ReMeetApp: App {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @StateObject private var mapController = MapController()

    var body: some Scene {
        WindowGroup {
            //MainAppView()
            if isLoggedIn {
                MainAppView(mapController: mapController) // ← renamed from HomeView
            } else {
                NavigationView {
                    WelcomeView()
                }
            }
        }
    }
}
