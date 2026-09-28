//
//  HNTheme.swift
//  HackerNews
//
//  Visual language matching news.ycombinator.com: HN orange chrome,
//  beige surfaces, gray metadata, Verdana type. The app is pinned to
//  the light style since the website has no dark mode.
//

import UIKit

enum HNTheme {
    static let orange = UIColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0) // #FF6600, both modes
    static let beige = dynamic( // #F6F6EF by day, warm charcoal by night
        light: UIColor(red: 0.965, green: 0.965, blue: 0.937, alpha: 1.0),
        dark: UIColor(red: 0.11, green: 0.106, blue: 0.09, alpha: 1.0)
    )
    static let pressedBeige = dynamic(
        light: UIColor(red: 0.91, green: 0.895, blue: 0.82, alpha: 1.0),
        dark: UIColor(red: 0.20, green: 0.19, blue: 0.16, alpha: 1.0)
    )
    static let gray = UIColor(red: 0x82 / 255.0, green: 0x82 / 255.0, blue: 0x82 / 255.0, alpha: 1.0) // #828282, both modes
    static let text = dynamic(
        light: .black,
        dark: UIColor(red: 0.95, green: 0.94, blue: 0.90, alpha: 1.0)
    )
    static let tabSelected = UIColor { traits in
        traits.userInterfaceStyle == .dark ? .white : .black
    }
    static let tabUnselected = UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.6)
            : UIColor.black.withAlphaComponent(0.55)
    }

    private static func dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        }
    }
}

extension HNTheme {
    /// SF Pro: drawn for on-device legibility (replaces Verdana, whose tight
    /// spacing and small x-height strain at list sizes). Sizes stay close to
    /// the site's proportions; Dynamic Type scaling is preserved.
    static func font(size: CGFloat, weight: UIFont.Weight, textStyle: UIFont.TextStyle) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }

    static var titleFont: UIFont { font(size: 17, weight: .semibold, textStyle: .headline) }
    static var metaFont: UIFont { font(size: 12, weight: .regular, textStyle: .footnote) }
    static var rankFont: UIFont { font(size: 13, weight: .regular, textStyle: .footnote) }
    static var navTitleFont: UIFont { font(size: 16, weight: .bold, textStyle: .headline) }
    static var tabFont: UIFont { font(size: 11, weight: .regular, textStyle: .footnote) }
    static var commentFont: UIFont { font(size: 14, weight: .regular, textStyle: .body) }

    static func pressedBackgroundView() -> UIView {
        let view = UIView()
        view.backgroundColor = pressedBeige
        return view
    }
}
