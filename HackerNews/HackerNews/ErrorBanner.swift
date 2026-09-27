//
//  LoadMoreErrorBanner.swift
//  HackerNews
//
//  Non-blocking translucent banner pinned above the bottom safe area,
//  shown when a pagination request fails while content is on screen.
//

import UIKit

final class LoadMoreErrorBanner: UIView {
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)
    private var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        layer.cornerRadius = 12
        layer.masksToBounds = true

        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        messageLabel.font = .preferredFont(forTextStyle: .footnote)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 2

        retryButton.setTitle("Retry", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .footnote)
        retryButton.setContentHuggingPriority(.required, for: .horizontal)
        retryButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [messageLabel, retryButton])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor, constant: -10),
        ])
    }

    func configure(message: String, onRetry: @escaping () -> Void) {
        messageLabel.text = message
        self.onRetry = onRetry
    }

    @objc private func didTapRetry() {
        onRetry?()
    }
}
