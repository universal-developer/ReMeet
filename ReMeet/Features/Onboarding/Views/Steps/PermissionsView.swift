//
//  PermissionsView.swift
//  ReMeet
//
//  Created by Artush on 19/03/2025.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct PermissionsView: View {
    @ObservedObject var model: OnboardingModel
    @State private var permissionStage: PermissionStage = .location
    @StateObject private var locationManager = LocationPermissionManager()
    @AppStorage("isLoggedIn") var isLoggedIn = false
    
    enum PermissionStage {
        case location
        case notifications
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // MARK: - Icon
            ZStack {
                Circle()
                    .fill(Color(hex: "C9155A").opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: permissionStage == .location ? "location.fill" : "bell.fill")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "C9155A"))
            }

            // MARK: - Text
            Group {
                Text(permissionStage == .location ? "Can we access your location?" : "Enable notifications")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text(permissionStage == .location
                     ? "We'll show you people you meet nearby—at events, venues, or on the go."
                     : "We’ll let you know when someone reconnects with you or visits a place you’ve been.")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            }

            Spacer()

            // MARK: - Buttons
            if permissionStage == .location {
                PrimaryButton(
                    title: "Enable Location",
                    action: requestLocationPermission
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 16) {
                    PrimaryButton(
                        title: "Enable Notifications",
                        action: requestNotificationPermission
                    )
                    .padding(.horizontal, 20)

                    Button(action: skipNotifications) {
                        Text("Not now")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding(.bottom, 40)
        .onChange(of: locationManager.authorizationStatus) { status in
            if status != .notDetermined {
                // Transition to notifications smoothly
                withAnimation {
                    permissionStage = .notifications
                }
            }
        }
    }

    // MARK: - Permissions
    private func requestLocationPermission() {
        locationManager.requestPermission()
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
            DispatchQueue.main.async {
                model.moveToNextStep()
            }
        }
    }

    private func skipNotifications() {
        model.moveToNextStep()
    }
}

// MARK: - Location Permission Manager
class LocationPermissionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

#Preview {
    PermissionsView(model: OnboardingModel())
}
