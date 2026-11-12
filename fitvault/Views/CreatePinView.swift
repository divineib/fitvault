// file: CreatePinView.swift
// what: first-launch screen. the user types a pin, types it again, and picks face id on or off.
// story: us02

import SwiftUI

struct CreatePinView: View {
    @EnvironmentObject var lock: LockManager

    // the three steps of making a pin
    private enum Step {
        case enter, confirm, biometrics
    }

    @State private var step: Step = .enter
    @State private var firstPin = ""
    @State private var pin = ""
    @State private var message: String?
    @State private var useBiometrics = true

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tint)

            switch step {
            case .enter, .confirm:
                pinStep
            case .biometrics:
                biometricsStep
            }
            Spacer()
        }
        .padding()
    }

    // MARK: steps

    private var pinStep: some View {
        VStack(spacing: 24) {
            Text(step == .enter ? "create a pin" : "confirm your pin")
                .font(.title2.bold())
            Text(message ?? hint)
                .font(.subheadline)
                .foregroundStyle(message == nil ? Color.secondary : Color.red)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)

            PinPad(pin: $pin, onSubmit: submitPin)
        }
    }

    // the small grey text under the title
    private var hint: String {
        step == .enter
            ? "use 4 to 6 digits. you'll need it every time you open fitvault."
            : "type the same pin again."
    }

    private var biometricsStep: some View {
        VStack(spacing: 24) {
            Text("unlock faster")
                .font(.title2.bold())

            Toggle("unlock with \(Biometrics.name())", isOn: $useBiometrics)
                .disabled(!Biometrics.isAvailable())
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                // start switched off if this phone has no face id set up
                .onAppear { useBiometrics = Biometrics.isAvailable() }

            if !Biometrics.isAvailable() {
                Text("\(Biometrics.name()) isn't set up on this phone. you can turn it on later in settings.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("done") {
                try? lock.createPin(firstPin, useBiometrics: useBiometrics && Biometrics.isAvailable())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    // MARK: actions

    private func submitPin() {
        switch step {
        case .enter:
            guard PinRules.isValid(pin) else {
                message = "a pin must be 4 to 6 digits."
                return
            }
            firstPin = pin
            pin = ""
            message = nil
            step = .confirm
        case .confirm:
            if pin == firstPin {
                step = .biometrics
            } else {
                // start over if the two pins don't match
                message = "pins didn't match. try again."
                firstPin = ""
                pin = ""
                step = .enter
            }
        case .biometrics:
            break
        }
    }
}
