//
//  SquareButton.swift
//  ReMeet
//
//  Created by Artush on 14/06/2025.
//

import SwiftUI

struct SquareButton: View {
    var text: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            Button(action: action) {
                Image(systemName: "\(icon)")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: 60, height: 60)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            Text("\(text)")
                .font(.footnote)
                .foregroundColor(.primary)
        }
    }
}

