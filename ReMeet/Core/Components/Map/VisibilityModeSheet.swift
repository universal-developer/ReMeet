//
//  VisibilityModeSheet.swift
//  ReMeet
//
//  Created by Artush on 01/05/2025.
//

import SwiftUI

struct VisibilityModeSheet: View {
    @Binding var isGhostMode: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.4))
                .padding(.top, 12)

            Text("Visibility Mode")
                .font(.title2)
                .bold()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("👻 Ghost Mode")
                        .font(.headline)

                    Spacer()

                    Toggle("Ghost Mode", isOn: $isGhostMode)
                        .onChange(of: isGhostMode) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "isGhostMode")
                            NotificationCenter.default.post(name: .shouldUpdateUserAnnotation, object: nil)
                        }
                }

                Text("You’ll be invisible to others on the map until you turn this off.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Spacer()

            Button("Done") {
                dismiss()
            }
            .padding()
        }
        .presentationDetents([.medium])
    }
}
