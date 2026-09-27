//
//  StoryViewCell.swift
//  HackerNews
//
//  Programmatic self-sizing cell matching news.ycombinator.com rows:
//  gray rank, upvote arrow, black title with gray (domain), and a gray
//  "points by user time | comments" metadata line.
//

import UIKit

final class StoryViewCell: UITableViewCell {
    static let reuseIdentifier = "StoryViewCell"

    private let rankLabel = UILabel()
    private let voteArrowView = UIImageView(image: UIImage(systemName: "arrowtriangle.up.fill"))
    private let rankStack = UIStackView()
    private let titleLabel = UILabel()
    private let metaLabel = UILabel()
    private let textStack = UIStackView()
    private let outerStack = UIStackView()

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

        rankLabel.font = HNTheme.rankFont
        rankLabel.adjustsFontForContentSizeCategory = true
        rankLabel.textColor = HNTheme.gray
        rankLabel.textAlignment = .right
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.widthAnchor.constraint(equalToConstant: 30).isActive = true
        rankLabel.setContentHuggingPriority(.required, for: .horizontal)

        voteArrowView.tintColor = HNTheme.gray
        voteArrowView.contentMode = .scaleAspectFit
        voteArrowView.translatesAutoresizingMaskIntoConstraints = false
        voteArrowView.widthAnchor.constraint(equalToConstant: 12).isActive = true
        voteArrowView.heightAnchor.constraint(equalToConstant: 12).isActive = true
        voteArrowView.setContentHuggingPriority(.required, for: .horizontal)

        rankStack.axis = .horizontal
        rankStack.spacing = 4
        rankStack.alignment = .center
        rankStack.addArrangedSubview(rankLabel)
        rankStack.addArrangedSubview(voteArrowView)

        titleLabel.numberOfLines = 3
        titleLabel.lineBreakMode = .byTruncatingTail

        metaLabel.font = HNTheme.metaFont
        metaLabel.adjustsFontForContentSizeCategory = true
        metaLabel.textColor = HNTheme.gray
        metaLabel.numberOfLines = 1
        metaLabel.lineBreakMode = .byTruncatingTail

        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(metaLabel)

        outerStack.axis = .horizontal
        outerStack.spacing = 6
        outerStack.alignment = .top
        outerStack.addArrangedSubview(rankStack)
        outerStack.addArrangedSubview(textStack)
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(outerStack)

        NSLayoutConstraint.activate([
            outerStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            outerStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            outerStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            outerStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        rankLabel.text = nil
        titleLabel.attributedText = nil
        metaLabel.text = nil
        accessibilityLabel = nil
    }

    func configure(with item: HNItem?, rank: Int?) {
        guard let item else {
            rankLabel.text = nil
            titleLabel.attributedText = nil
            metaLabel.text = nil
            accessibilityLabel = nil
            return
        }

        if let rank {
            rankLabel.text = "\(rank)."
        } else {
            rankLabel.text = nil
        }

        let title = NSMutableAttributedString(
            string: item.title ?? "(no title)",
            attributes: [.font: HNTheme.titleFont, .foregroundColor: UIColor.black]
        )
        if let host = item.domainHost {
            title.append(NSAttributedString(
                string: " (\(host))",
                attributes: [.font: HNTheme.metaFont, .foregroundColor: HNTheme.gray]
            ))
        }
        titleLabel.attributedText = title

        var leading: [String] = []
        if let score = item.score, score > 0 {
            leading.append(score == 1 ? "1 point" : "\(score) points")
        }
        if let by = item.by {
            leading.append("by \(by)")
        }
        if let ago = item.timeAgoDisplay {
            leading.append(ago)
        }
        let commentsText: String
        if let count = item.descendants, count > 0 {
            commentsText = count == 1 ? "1 comment" : "\(count) comments"
        } else {
            commentsText = "discuss"
        }
        let head = leading.joined(separator: " ")
        metaLabel.text = head.isEmpty ? commentsText : "\(head) | \(commentsText)"

        accessibilityLabel = [item.title, metaLabel.text]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}
