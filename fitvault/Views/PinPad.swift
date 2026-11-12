// file: PinPad.swift
// what: the number keypad and dots used on the create-pin and lock screens.
// story: us02

import SwiftUI

struct PinPad: View {
    @Binding var pin: String
    var isDisabled = false
    // runs when the user taps the check mark
    let onSubmit: () -> Void

    private let rows = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]

    var body: some View {
        VStack(spacing: 28) {
            // one dot per possible digit, filled for each digit typed
            HStack(spacing: 14) {
                ForEach(0..<PinRules.maxLength, id: \.self) { index in
                    Circle()
                        .fill(index < pin.count ? Color.primary : Color.clear)
                        .overlay(Circle().stroke(Color.primary, lineWidth: 1.5))
                        .frame(width: 14, height: 14)
                }
            }
            .accessibilityLabel("\(pin.count) digits entered")

            VStack(spacing: 16) {
                ForEach(rows, id: \.self) { row in
                    HStack(spacing: 24) {
                        ForEach(row, id: \.self) { digit in
                            digitButton(digit)
                        }
                    }
                }
                HStack(spacing: 24) {
                    // delete the last digit
                    keyButton(systemImage: "delete.left", label: "delete") {
                        if !pin.isEmpty { pin.removeLast() }
                    }
                    .disabled(pin.isEmpty)

                    digitButton("0")

                    // submit, only once at least 4 digits are typed
                    keyButton(systemImage: "checkmark", label: "enter") {
                        onSubmit()
                    }
                    .disabled(pin.count < PinRules.minLength)
                }
            }
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.4 : 1)
        }
    }

    private func digitButton(_ digit: String) -> some View {
        Button {
            if pin.count < PinRules.maxLength { pin.append(digit) }
        } label: {
            Text(digit)
                .font(.title)
                .frame(width: 76, height: 76)
                .background(Circle().fill(Color(.secondarySystemFill)))
                // makes the whole circle tappable, not just the number
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func keyButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2)
                .frame(width: 76, height: 76)
                // makes the whole circle tappable, not just the icon
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
