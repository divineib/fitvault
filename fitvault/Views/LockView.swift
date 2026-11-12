// file: LockView.swift
// what: the lock screen. asks for the pin or face id, and shows the 30-second block after 5 wrong pins.
// story: us02

import SwiftUI

struct LockView: View {
    @EnvironmentObject var lock: LockManager
    @State private var pin = ""
    @State private var message: String?

    var body: some View {
        // redraw every second so the countdown updates
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let lockedOut = lock.lockout.isLockedOut(now: context.date)

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)
                Text("fitvault is locked")
                    .font(.title2.bold())

                Group {
                    if lockedOut {
                        Text("too many wrong pins. try again in \(lock.lockout.secondsLeft(now: context.date)) seconds.")
                            .foregroundStyle(.red)
                    } else if let message {
                        Text(message).foregroundStyle(.red)
                    } else {
                        Text("enter your pin").foregroundStyle(.secondary)
                    }
                }
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .frame(minHeight: 40)

                PinPad(pin: $pin, isDisabled: lockedOut, onSubmit: submitPin)

                if lock.biometricsEnabled {
                    Button {
                        Task { await lock.tryBiometrics() }
                    } label: {
                        Label("use \(Biometrics.name())", systemImage: "faceid")
                    }
                } else {
                    // keeps the layout the same height
                    Color.clear.frame(height: 22)
                }
                Spacer()
            }
            .padding()
        }
        .task {
            // ask for face id as soon as the lock screen shows
            await lock.tryBiometrics()
        }
    }

    private func submitPin() {
        let worked = lock.tryPin(pin)
        pin = ""
        if worked {
            message = nil
        } else if lock.lockout.isLockedOut(now: Date()) {
            message = nil
        } else {
            let left = lock.lockout.attemptsLeft
            message = "wrong pin. \(left) \(left == 1 ? "try" : "tries") left."
        }
    }
}
