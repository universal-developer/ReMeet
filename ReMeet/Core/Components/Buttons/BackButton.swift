//
//  BackButton.swift
//  ReMeet
//
//  Created by Artush on 21/02/2025.
//

import SwiftUI

struct BackButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(hex: "C9155A"))
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 16)
        }
    }
}

#Preview {
    BackButton(title: "Continue", action: {})
}

