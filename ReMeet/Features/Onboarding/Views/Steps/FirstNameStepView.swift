import SwiftUI

struct FirstNameStepView: View {
    @ObservedObject var model: OnboardingModel
    @Environment(\.colorScheme) var colorScheme

    var isValid: Bool {
        model.currentStep.validate(model: model)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Let's get started, what's your name?")
                .font(.title3)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.top, 20)

            TextField("First name", text: $model.firstName)
                .font(.system(size: 32))
                .fontWeight(.bold)
                .textFieldStyle(PlainTextFieldStyle())
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Spacer()

            PrimaryButton(
                title: "Next",
                action: {
                    model.moveToNextStep()
                },
                backgroundColor: isValid ? Color(hex: "C9155A") : Color.gray.opacity(0.5)
            )
            .frame(maxWidth: .infinity)
            .disabled(!isValid)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

#Preview {
    FirstNameStepView(model: OnboardingModel())
}
