//
//  StoryListErrorView.swift
//  HackerNews
//
//  Full-screen error used as the table background view when there is
//  no content, and as the web-view error overlay in the detail screen.
//

import UIKit

final class StoryListErrorView: UIView {
    private let titleLabel = UILabel()
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
        backgroundColor = HNTheme.beige

        titleLabel.font = .preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.text = "Couldn't load stories"

        messageLabel.font = .preferredFont(forTextStyle: .subheadline)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.setTitle("Try Again", for: .normal)
        retryButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        retryButton.addTarget(self, action: #selector(didTapRetry), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -32),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    func configure(message: String, title: String? = nil, onRetry: @escaping () -> Void) {
        if let title { titleLabel.text = title }
        messageLabel.text = message
        self.onRetry = onRetry
    }

    @objc private func didTapRetry() {
        onRetry?()
    }
}
