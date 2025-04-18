//
//  ZoomSliderView.swift
//  ReMeet
//
//  Created by Artush on 18/04/2025.
//

import SwiftUI
import MapboxMaps

struct ZoomSlider: View {
    let mapView: MapView
    @State private var isExpanded = false
    @State private var dragOffset: CGFloat = 0.5 // Normalized: 0 = top, 1 = bottom

    let minZoom: CGFloat = 3
    let maxZoom: CGFloat = 20

    var zoomLevel: CGFloat {
        minZoom + (1.0 - dragOffset) * (maxZoom - minZoom)
    }

    var body: some View {
        GeometryReader { geometry in
            let fullHeight = geometry.size.height * 0.85
            let sliderWidth: CGFloat = isExpanded ? 44 : 6

            ZStack(alignment: .trailing) {
                if isExpanded {
                    ZStack {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: sliderWidth, height: fullHeight)
                            .shadow(radius: 4)

                        // Draggable thumb
                        Circle()
                            .fill(Color(hex: "C9155A"))
                            .frame(width: 28, height: 28)
                            .offset(y: dragOffsetPosition(fullHeight: fullHeight))
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let y = value.location.y
                                        let clampedY = max(0, min(y, fullHeight))
                                        dragOffset = 1.0 - (clampedY / fullHeight)
                                        updateZoom()
                                    }
                            )

                        // Icons
                        VStack {
                            Image(systemName: "plus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                            Spacer()
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.gray)
                        }
                        .padding(6)
                    }
                    .padding(.trailing, 10)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isExpanded)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.9))
                        .frame(width: sliderWidth, height: fullHeight)
                        .padding(.trailing, 6)
                        .onTapGesture {
                            withAnimation {
                                isExpanded = true
                            }
                        }
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .padding(.trailing, 4)
            .padding(.bottom, 100)
        }
    }

    private func dragOffsetPosition(fullHeight: CGFloat) -> CGFloat {
        // Map normalized value to y-position (centered relative to capsule)
        let range = fullHeight
        return (dragOffset - 0.5) * range
    }

    private func updateZoom() {
        mapView.mapboxMap.setCamera(to: CameraOptions(zoom: zoomLevel))
        print("📍 Zoom level: \(zoomLevel)")
    }
}
