//
//  ThemeManager.swift
//  HackerNews
//
//  Light / dark / automatic appearance, persisted and applied to the window.
//  Defaults to light.
//

import UIKit

enum ThemeMode: String, CaseIterable {
    case light
    case dark
    case automatic

    var title: String { rawValue.capitalized }

    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .automatic: return .unspecified
        }
    }
}

enum ThemeManager {
    private static let storageKey = "hn.appearance"

    static var current: ThemeMode {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey) else { return .light }
            return ThemeMode(rawValue: raw) ?? .light
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: storageKey) }
    }

    static func apply(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = current.userInterfaceStyle
    }

    static func set(_ mode: ThemeMode, window: UIWindow?) {
        current = mode
        apply(to: window)
    }
}
