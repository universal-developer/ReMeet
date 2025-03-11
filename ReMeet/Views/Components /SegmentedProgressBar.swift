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
    
    var activeColor: Color = Color(hex: "C9155A")
    var inactiveColor: Color = Color.gray.opacity(0.3)
    var fillCurrentStep: Bool = false
    var spacing: CGFloat = 6
    var height: CGFloat = 4
    
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(fillCurrentStep ? (step <= currentStep ? activeColor : inactiveColor) :
                                           (step < currentStep ? activeColor : inactiveColor))
                    .frame(height: height)
            }
        }
    }
}

struct SegmentedProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        SegmentedProgressBar(totalSteps: 5, currentStep: 2)
            .padding()
            .background(Color.black)
            .preferredColorScheme(.dark)
    }
}
