//
//  PermissionsView.swift
//  ReMeet
//
//  Created by Artush on 19/03/2025.
//

import SwiftUI
import CoreLocation

struct PermissionsView: View {
    @ObservedObject var model: OnboardingModel  
    @State private var permissionStage: PermissionStage = .location
    @StateObject private var locationManager = LocationPermissionManager()
    
    enum PermissionStage {
        case location
        case notifications
        case completed
    }
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Icon at the top
            ZStack {
                Circle()
                    .fill(Color(hex: "F5CA5A").opacity(0.2))
                    .frame(width: 70, height: 70)
                
                if permissionStage == .location {
                    Image(systemName: "location.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "F5CA5A"))
                } else {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 36))
                        .foregroundColor(Color(hex: "F5CA5A"))
                }
            }
            
            // Title and description
            if permissionStage == .location {
                Text("Now, can we get your location?")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("We need it so we can show you all the great people nearby (or far away).")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            } else {
                Text("Don't miss a beat, or a match")
                    .font(.system(size: 28, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Turn on your notifications so we can let you know when you have new connections nearby.")
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            Spacer()
            
            // Action buttons
            if permissionStage == .location {
                Button(action: requestLocationPermission) {
                    Text("Set location services")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.darkGray))
                        .foregroundColor(.white)
                        .cornerRadius(30)
                        .padding(.horizontal, 20)
                }
            } else {
                VStack(spacing: 16) {
                    Button(action: requestNotificationPermission) {
                        Text("Allow notifications")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.darkGray))
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .padding(.horizontal, 20)
                    }
                    
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
                // Move to notifications after location permission is decided
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    permissionStage = .notifications
                }
            }
        }
    }
    
    private func requestLocationPermission() {
        locationManager.requestPermission()
    }
    
    private func requestNotificationPermission() {
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                completeOnboarding()
            }
        }
    }
    
    private func skipNotifications() {
        completeOnboarding()
    }
    
    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
        // Close the onboarding and go to main app
        model.moveToNextStep()
    }
}

// Helper class to manage location permissions
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
