//
//  WrapTags.swift
//  ReMeet
//
//  Created by Artush on 12/05/2025.
//

import SwiftUI

struct WrapTags: View {
    let tags: [String]

    var body: some View {
        FlexibleView(
            availableWidth: UIScreen.main.bounds.width - 40,
            data: tags,
            spacing: 8,
            alignment: .leading
        ) { tag in
            Text(tag)
                .font(.caption)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.15))
                .cornerRadius(20)
        }
    }
}


