//
//  PrimaryButton.swift
//  ReMeet
//
//  Created by Artush on 21/02/2025.
//

import SwiftUI

struct PrimaryButton: View {
    var title: String
    var action: () -> Void
    var backgroundColor: Color = Color(hex: "C9155A")

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity) 
                .padding()
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
}
