//
//  HNCommentCell.swift
//  HackerNews
//
//  Comment rows for the Comments tab: stripped comment text plus a
//  gray "by user time | on: story" metadata line.
//

import UIKit

final class HNCommentCell: UITableViewCell {
    static let reuseIdentifier = "HNCommentCell"

    private let bodyLabel = UILabel()
    private let metaLabel = UILabel()
    private let stack = UIStackView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        selectionStyle = .default
        backgroundColor = HNTheme.beige
        selectedBackgroundView = HNTheme.pressedBackgroundView()
        isAccessibilityElement = true

        bodyLabel.font = HNTheme.commentFont
        bodyLabel.adjustsFontForContentSizeCategory = true
        bodyLabel.textColor = HNTheme.text
        bodyLabel.numberOfLines = 4
        bodyLabel.lineBreakMode = .byTruncatingTail

        metaLabel.font = HNTheme.metaFont
        metaLabel.adjustsFontForContentSizeCategory = true
        metaLabel.textColor = HNTheme.gray
        metaLabel.numberOfLines = 1
        metaLabel.lineBreakMode = .byTruncatingTail

        stack.axis = .vertical
        stack.spacing = 4
        stack.addArrangedSubview(bodyLabel)
        stack.addArrangedSubview(metaLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        bodyLabel.text = nil
        metaLabel.text = nil
        accessibilityLabel = nil
    }

    func configure(with item: HNItem?, parentTitle: String?) {
        guard let item else {
            bodyLabel.text = nil
            metaLabel.text = nil
            accessibilityLabel = nil
            return
        }

        let text = item.plainText
        bodyLabel.text = (text?.isEmpty ?? true) ? "[deleted]" : text

        var parts: [String] = []
        if let by = item.by {
            parts.append("by \(by)")
        }
        if let ago = item.timeAgoDisplay {
            parts.append(ago)
        }
        var meta = parts.joined(separator: " ")
        if let parentTitle, !parentTitle.isEmpty {
            meta += (meta.isEmpty ? "" : " | ") + "on: \(parentTitle)"
        }
        metaLabel.text = meta

        accessibilityLabel = [bodyLabel.text, meta]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
