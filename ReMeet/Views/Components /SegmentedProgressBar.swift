//
//  SegmentedProgressBar.swift
//  ReMeet
//
//  Created by Artush on 11/03/2025.
//

import SwiftUI

struct SegmentedProgressBar: View {
    let totalSteps: Int
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step < currentStep ? Color(hex: "C9155A") : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
    }
}
