//
//  SkeletonLoadingView.swift
//  HackerNews
//
//  Placeholder rows with a sweeping sheen shown behind the table
//  while the first page loads. Static when Reduce Motion is on.
//

import UIKit

final class SkeletonLoadingView: UIView {
    private let rowCount = 8
    private var sheen: CAGradientLayer?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = HNTheme.beige

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 16),
        ])

        for index in 0..<rowCount {
            let row = UIStackView()
            row.axis = .vertical
            row.spacing = 8
            row.alignment = .leading

            let titleBar = UIView()
            titleBar.backgroundColor = .secondarySystemFill
            titleBar.layer.cornerRadius = 5
            titleBar.heightAnchor.constraint(equalToConstant: 16).isActive = true

            let metaBar = UIView()
            metaBar.backgroundColor = .tertiarySystemFill
            metaBar.layer.cornerRadius = 4
            metaBar.heightAnchor.constraint(equalToConstant: 12).isActive = true

            row.addArrangedSubview(titleBar)
            row.addArrangedSubview(metaBar)
            stack.addArrangedSubview(row)

            titleBar.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: index % 3 == 2 ? 0.6 : 0.9).isActive = true
            metaBar.widthAnchor.constraint(equalTo: row.widthAnchor, multiplier: 0.45).isActive = true
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startSheen()
        } else {
            stopSheen()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sheen?.frame = bounds
    }

    private func startSheen() {
        guard sheen == nil, !UIAccessibility.isReduceMotionEnabled else { return }
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.09).cgColor,
            UIColor.clear.cgColor,
        ]
        gradient.locations = [0, 0.5, 1]
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        gradient.frame = bounds
        layer.addSublayer(gradient)

        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.duration = 1.6
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        gradient.add(animation, forKey: "sheen")
        sheen = gradient
    }

    private func stopSheen() {
        sheen?.removeFromSuperlayer()
        sheen = nil
    }
}
