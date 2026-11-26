// file: PrivacyWindow.swift
// what: shows the privacy cover in its own window above everything,
//       including sheets and alerts, while the app isn't active.
// story: us15

import SwiftUI
import UIKit

@MainActor
enum PrivacyWindow {
    // the cover window while it's showing, nil the rest of the time
    private static var window: UIWindow?

    static func show() {
        guard window == nil,
              let scene = UIApplication.shared.connectedScenes
                  .compactMap({ $0 as? UIWindowScene })
                  .first else { return }
        let cover = UIWindow(windowScene: scene)
        cover.rootViewController = UIHostingController(rootView: PrivacyCoverView())
        cover.windowLevel = .alert + 1   // sits above sheets and alerts
        cover.isHidden = false
        window = cover
    }

    static func hide() {
        window?.isHidden = true
        window = nil                     // nothing is left over while you use the app
    }
}
