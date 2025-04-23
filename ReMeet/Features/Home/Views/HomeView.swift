//
//  HomeView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//

import SwiftUI
import MapboxMaps

struct HomeMapScreen: View {
    @AppStorage("hasLoadedMapOnce") private var hasLoadedMapOnce: Bool = false
    
    @State private var myUserId: String?
    @State private var tappedUserId: String?
    @State private var showModal = false
    @State private var mapIsVisible = false
    @State private var isFirstLoad = true
    @State private var mapIsReady = false
    @State private var tappedUserName: String? = nil
    @State private var tappedUserPhotoURL: String? = nil

    //@State private var sliderVisible = true
    
    @GestureState private var dragOffset: CGSize = .zero
    
    var orchestrator: MapOrchestrator

    var body: some View {
        ZStack {
            // Prevent white flash on startup
            if isFirstLoad {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.5), value: mapIsReady)
            }

                // Map layer
            if let userId = myUserId {
                MapViewRepresentable(controller: orchestrator.mapController)
                    .ignoresSafeArea()
                    .opacity((hasLoadedMapOnce || mapIsVisible) ? 1 : 0)
                    .onAppear {
                        // Eagerly load initials + photo
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .didTapUserAnnotation)) { notification in
                        if let userId = notification.userInfo?["userId"] as? String {
                            tappedUserId = userId
                            tappedUserName = notification.userInfo?["firstName"] as? String
                            tappedUserPhotoURL = notification.userInfo?["photoURL"] as? String
                            withAnimation {
                                showModal = true
                            }
                        }
                    }


                    .onReceive(NotificationCenter.default.publisher(for: .mapDidBecomeVisible)) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            mapIsVisible = true
                            isFirstLoad = false
                            hasLoadedMapOnce = true // ✅ Mark it as loaded so we skip fade next time
                        }
                    }

            } /*else {
                // Optional loading indicator while fetching user session
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }*/

            // Zoom slider (auto-hides after 5s)
            /*if sliderVisible {
                ZoomSlider(mapView: mapController.mapView)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .padding(.trailing, 12)
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .onAppear {
                        startAutoHideTimer()
                    }
                    .onTapGesture {
                        withAnimation {
                            sliderVisible = false
                        }
                    }
            }*/

            // Header: avatar, search, settings
            headerView

            VStack {
                Spacer()

                HStack() {

                    Button(action: {
                        orchestrator.mapController.recenterOnUser()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black)
                            .frame(width: 40, height: 40)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 40)
                }
            }
            .frame(maxWidth: .infinity, alignment: .bottom)
            
            // Transparent background to close preview on tap
            if showModal {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation {
                            showModal = false
                        }
                    }
            }
        }
        .onAppear {
            Task {
                do {
                    let session = try await SupabaseManager.shared.client.auth.session
                    myUserId = session.user.id.uuidString
                } catch {
                    print("❌ Failed to fetch session: \(error)")
                }
            }
        }
        // Snapchat-style bottom modal
        .safeAreaInset(edge: .bottom, alignment: .center, spacing: 0) {
            if showModal, let userId = tappedUserId {
                FastUserPreviewSheet(
                    userId: userId,
                    initialFirstName: tappedUserName,
                    profileImage: cachedImage(from: tappedUserPhotoURL),
                    onClose: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showModal = false
                        }
                    }
                )
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showModal)
                .padding(.bottom, 12)
                .gesture(
                    DragGesture()
                        .updating($dragOffset) { value, state, _ in
                            state = value.translation
                        }
                        .onEnded { value in
                            if value.translation.height > 80 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    showModal = false
                                }
                            }
                        }
                )
            }
        }

    }

    private var headerView: some View {
        VStack {
            HStack(spacing: 12) {
                // Avatar
                Button(action: {
                    print("👤 Avatar tapped")
                }) {
                    Image("profilePlaceholder")
                        .resizable()
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                }

                Spacer()

                // Search pill
                Button(action: {
                    print("🔍 Search tapped")
                }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Earth")
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }

                Spacer()

                // Settings
                Button(action: {
                    print("⚙️ Settings tapped")
                }) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            .padding(.top, 30)

            Spacer()
        }
    }
    
    func cachedImage(from urlStr: String?) -> UIImage? {
        guard let urlStr = urlStr,
              let url = URL(string: urlStr),
              let data = try? Data(contentsOf: url),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }


    /*private func startAutoHideTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            withAnimation {
                sliderVisible = false
            }
        }
    }*/
}




/*#Preview {
    HomeMapScreen(mapController: MapController())
}*/
