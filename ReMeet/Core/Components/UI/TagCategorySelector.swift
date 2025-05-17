//
//  TagCategorySelector.swift
//  ReMeet
//
//  Created by Artush on 16/05/2025.
//


import SwiftUI

struct TagCategorySelector: View {
    //let title: String
    let tags: [SelectableTag]
    let selectionLimit: Int
    @Binding var selected: Set<SelectableTag>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            //Text(title)
                //.font(.subheadline)
                //.fontWeight(.bold)
            FlexibleView(
                availableWidth: UIScreen.main.bounds.width - 40,
                data: tags,
                spacing: 8,
                alignment: .leading
            ) { tag in
                tagView(for: tag)
                    .onTapGesture { toggle(tag) }
            }

        }
        .padding(.vertical, 8)
    }

    private func tagView(for tag: SelectableTag) -> some View {
        HStack(spacing: 6) {
            Image(systemName: tag.iconName)
                .font(.system(size: 13))
            Text(tag.label)
                .font(.caption)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(selected.contains(tag) ? Color(hex: "C9155A").opacity(0.2) : Color.gray.opacity(0.1))
        .foregroundColor(.primary)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(selected.contains(tag) ? Color(hex: "C9155A") : Color.gray.opacity(0.3), lineWidth: 1)
        )
        .cornerRadius(20)
    }

    private func toggle(_ tag: SelectableTag) {
        if selected.contains(tag) {
            selected.remove(tag)
        } else {
            guard selected.count < selectionLimit || selectionLimit == .max else { return }
            selected.insert(tag)
        }
    }
}
