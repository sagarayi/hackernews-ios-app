//
//  LegalTextViewController.swift
//  HackerNews
//
//  Read-only viewer for the embedded privacy policy and terms.
//

import UIKit

final class LegalTextViewController: UIViewController {
    private let bodyText: String

    init(title: String, text: String) {
        self.bodyText = text
        super.init(nibName: nil, bundle: nil)
        self.title = title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — LegalTextViewController is programmatic")
    }

    override func loadView() {
        let textView = UITextView()
        textView.backgroundColor = HNTheme.beige
        textView.textColor = HNTheme.text
        textView.font = HNTheme.font(size: 15, weight: .regular, textStyle: .body)
        textView.isEditable = false
        textView.isSelectable = true
        textView.dataDetectorTypes = .link
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 24, right: 12)
        textView.text = bodyText
        view = textView
    }
}
