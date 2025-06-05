//  PhotoCellView.swift
//  ReMeet
//
//  Extracted from ImageGrid.swift to be reusable

import SwiftUI

struct PhotoCellView: View {
    let item: ImageItem
    let index: Int
    let isMain: Bool
    let colorScheme: ColorScheme
    let showDelete: Bool
    let onDelete: () -> Void
    let onSetMain: () -> Void
    let onDragStart: () -> NSItemProvider
    let onDrop: () -> Bool
    let onLongPress: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            GeometryReader { geo in
                if let uiImage = item.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .onDrag {
                            onDragStart()
                        }
                        .onDrop(of: [.text], isTargeted: nil) { _ in
                            onDrop()
                        }
                        .onTapGesture {
                            onSetMain()
                        }
                        .onLongPressGesture {
                            onLongPress()
                        }
                } else {
                    // Show shimmer skeleton until image loads
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: geo.size.width, height: geo.size.height)
                        .shimmering()
                }
                
                if showDelete {
                    Button(action: onDelete) {
                        ZStack {
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(6)
                    .position(x: geo.size.width - 18, y: 18)
                }
                
                Group {
                    if isMain {
                        Text("Main")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .cornerRadius(4)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .cornerRadius(4)
                    }
                }
                .padding(6)
                .position(x: 40, y: geo.size.height - 20)
            }
            
            .aspectRatio(1, contentMode: .fit)
            .contentShape(Rectangle())
        }
    }
}
