//
//  HomeView.swift
//  ReMeet
//
//  Created by Artush on 10/04/2025.
//


import SwiftUI
import MapboxMaps

struct MapScreenView: View {
    @AppStorage("hasLoadedMapOnce") private var hasLoadedMapOnce: Bool = false
    @AppStorage("isGhostMode") private var isGhostMode = false // persists across sessions
        
    @State private var myUserId: String?
    @State private var tappedFriend: FriendLocationManager.Friend?
    @State private var tappedPreviewImage: UIImage?
    @State private var showModal = false
    @State private var mapIsVisible = false
    @State private var isFirstLoad = true
    @State private var showLocationAlert = false
    @State private var showVisibilitySheet = false
    
    @EnvironmentObject var profile: ProfileStore

    @GestureState private var dragOffset: CGSize = .zero
    
    var orchestrator: MapOrchestrator
    

    var body: some View {
        ZStack {
            if isFirstLoad {
                Color(.systemBackground)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .animation(.easeOut(duration: 0.5), value: mapIsVisible)
            }
            
            if myUserId != nil {
                MapViewRepresentable(orchestrator: orchestrator)
                    .ignoresSafeArea()
                    .opacity((hasLoadedMapOnce || mapIsVisible) ? 1 : 0)
                    .onReceive(NotificationCenter.default.publisher(for: .didTapUserAnnotation)) { notification in
                        handleAnnotationTap(notification)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .mapDidBecomeVisible)) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            mapIsVisible = true
                            isFirstLoad = false
                            hasLoadedMapOnce = true
                        }
                    }
            }
            
            headerView
            
            locationButton
            
            if showModal {
                Color.black.opacity(0.001)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation { showModal = false }
                    }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didUpdateMainProfilePhoto)) { _ in
            if let refreshed = ImageCacheManager.shared.loadFromDisk(forKey: "user_photo_main") {
                profile.userImage = refreshed
            }
        }
        .sheet(isPresented: $showVisibilitySheet) {
            VisibilityModeSheet(isGhostMode: $isGhostMode)
        }
        .onChange(of: orchestrator.locationController.permissionStatus) { newStatus in
            if newStatus == .denied || newStatus == .restricted {
                showLocationAlert = true
            }
        }
        .alert(isPresented: $showLocationAlert) {
            Alert(
                title: Text("Location Access Disabled"),
                message: Text("To show people nearby, please allow location access in Settings."),
                primaryButton: .default(Text("Open Settings")) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            fetchUserId()
            
        }
        .safeAreaInset(edge: .bottom, alignment: .center) {
            if showModal, let friend = tappedFriend {
                FastUserPreviewSheet(
                    userId: friend.friend_id,
                    initialFirstName: friend.first_name,
                    profileImage: tappedPreviewImage,
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
                                withAnimation { showModal = false }
                            }
                        }
                )
            }
        }
    }

    private var headerView: some View {
        VStack {
            HStack(spacing: 12) {
                Button(action: { print("👤 Avatar tapped") }) {
                    if let avatar = profile.userImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                    }

                }
                Spacer()
                Button(action: { print("🔍 Search tapped") }) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                        Text("Earth").fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
                Spacer()
                
                Button(action: { print("⚙️ Settings tapped"); showVisibilitySheet = true}) {
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

    private var locationButton: some View {
        VStack {
            Spacer()
            HStack {
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
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private func fetchUserId() {
        Task {
            do {
                let session = try await SupabaseManager.shared.client.auth.session
                myUserId = session.user.id.uuidString
            } catch {
                print("❌ Failed to fetch session: \(error)")
            }
        }
    }

    private func handleAnnotationTap(_ notification: NotificationCenter.Publisher.Output) {
        if let friend = notification.userInfo?["friend"] as? FriendLocationManager.Friend {
            tappedFriend = friend
            Task {
                tappedPreviewImage = await cachedImage(from: friend.photo_url)
                withAnimation { showModal = true }
            }
        } else if let userId = notification.userInfo?["userId"] as? String {
            tappedFriend = FriendLocationManager.Friend(
                friend_id: userId,
                first_name: profile.firstName ?? "You",
                latitude: nil,
                longitude: nil,
                photo_url: nil,
                is_ghost: false
            )
            tappedPreviewImage = profile.userImage
            withAnimation { showModal = true }
        } else {
            print("⚠️ Invalid tap payload")
        }
    }


    private func cachedImage(from urlStr: String?) async -> UIImage? {
        guard let urlStr = urlStr, let url = URL(string: urlStr) else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("⚠️ Failed to load image: \(error)")
            return nil
        }
    }
}
