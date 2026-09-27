//
//  StoryDetailViewController.swift
//  HackerNews
//
//  In-app reader: article web view with a translucent bottom toolbar
//  (back / forward / comments / share / open in Safari) and a thin
//  loading progress bar.
//

import UIKit
import WebKit

final class StoryDetailViewController: UIViewController {
    private enum Mode {
        case article
        case comments
    }

    // MARK: - Dependencies

    private let item: HNItem
    private var mode: Mode

    // MARK: - Views

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var bottomBar: UIVisualEffectView!
    private let backButton = UIButton(type: .system)
    private let forwardButton = UIButton(type: .system)
    private let commentsButton = UIButton(type: .system)
    private let shareButton = UIButton(type: .system)
    private let safariButton = UIButton(type: .system)
    private var errorOverlay: StoryListErrorView?

    private var progressObservation: NSKeyValueObservation?
    private var didAnimateBottomBar = false

    private let archiveButton = UIButton(type: .system)
    private var archiveSnapshotURL: URL?
    private let archiveChecker = ArchiveAvailability()

    // MARK: - URLs

    private var articleURL: URL? {
        item.url.flatMap(URL.init(string:))
    }

    private var commentsURL: URL {
        URL(string: "https://news.ycombinator.com/item?id=\(item.id)")!
    }

    private var currentURL: URL {
        if mode == .article, let articleURL { return articleURL }
        return commentsURL
    }

    // MARK: - Init

    init(item: HNItem) {
        self.item = item
        let hasArticle = item.url.flatMap(URL.init(string:)) != nil
        self.mode = hasArticle ? .article : .comments
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — StoryDetailViewController is programmatic")
    }

    deinit {
        progressObservation?.invalidate()
    }

    // MARK: - Lifecycle

    override func loadView() {
        let root = UIView()
        root.backgroundColor = HNTheme.beige
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        title = item.domainHost ?? "Story"
        setupWebView()
        setupProgressView()
        setupBottomBar()
        updateCommentsButton()
        loadCurrent()
        if articleURL != nil {
            Task { [weak self] in
                await self?.resolveArchiveButton()
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateBottomBarIn()
    }

    // MARK: - Setup

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        let web = WKWebView(frame: .zero, configuration: configuration)
        web.translatesAutoresizingMaskIntoConstraints = false
        web.navigationDelegate = self
        web.uiDelegate = self
        web.allowsBackForwardNavigationGestures = true
        web.backgroundColor = HNTheme.beige
        view.addSubview(web)
        self.webView = web

        progressObservation = web.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            self?.updateProgress(webView.estimatedProgress)
        }
    }

    private func setupProgressView() {
        let progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.trackTintColor = .clear
        progress.progressTintColor = HNTheme.orange
        progress.alpha = 0
        view.addSubview(progress)
        self.progressView = progress

        NSLayoutConstraint.activate([
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progress.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
    }

    private func setupBottomBar() {
        let bar = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.layer.cornerRadius = 16
        bar.layer.masksToBounds = true
        view.addSubview(bar)
        self.bottomBar = bar

        configureToolbarButton(backButton, systemName: "chevron.backward", action: #selector(didTapBack))
        configureToolbarButton(forwardButton, systemName: "chevron.forward", action: #selector(didTapForward))
        configureToolbarButton(commentsButton, systemName: "bubble.right", action: #selector(didTapComments))
        configureToolbarButton(archiveButton, systemName: "archivebox", action: #selector(didTapArchive))
        archiveButton.accessibilityLabel = "Archived copy"
        archiveButton.isHidden = true
        configureToolbarButton(shareButton, systemName: "square.and.arrow.up", action: #selector(didTapShare))
        configureToolbarButton(safariButton, systemName: "safari", action: #selector(didTapSafari))
        backButton.isEnabled = false
        forwardButton.isEnabled = false

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [backButton, forwardButton, spacer, commentsButton, archiveButton, shareButton, safariButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        bar.contentView.addSubview(stack)

        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: bar.topAnchor, constant: -8),

            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            stack.leadingAnchor.constraint(equalTo: bar.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: bar.contentView.trailingAnchor, constant: -12),
            stack.topAnchor.constraint(equalTo: bar.contentView.topAnchor, constant: 6),
            stack.bottomAnchor.constraint(equalTo: bar.contentView.bottomAnchor, constant: -6),

            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            forwardButton.widthAnchor.constraint(equalToConstant: 44),
            forwardButton.heightAnchor.constraint(equalToConstant: 44),
            commentsButton.widthAnchor.constraint(equalToConstant: 44),
            commentsButton.heightAnchor.constraint(equalToConstant: 44),
            archiveButton.widthAnchor.constraint(equalToConstant: 44),
            archiveButton.heightAnchor.constraint(equalToConstant: 44),
            shareButton.widthAnchor.constraint(equalToConstant: 44),
            shareButton.heightAnchor.constraint(equalToConstant: 44),
            safariButton.widthAnchor.constraint(equalToConstant: 44),
            safariButton.heightAnchor.constraint(equalToConstant: 44),
        ])

        bar.alpha = 0
        bar.transform = CGAffineTransform(translationX: 0, y: 16)
    }

    private func configureToolbarButton(_ button: UIButton, systemName: String, action: Selector) {
        button.setImage(UIImage(systemName: systemName), for: .normal)
        button.tintColor = .label
        button.addTarget(self, action: action, for: .touchUpInside)
    }

    // MARK: - Loading

    private func loadCurrent() {
        hideErrorOverlay()
        webView.load(URLRequest(url: currentURL))
    }

    private func updateProgress(_ value: Double) {
        progressView.setProgress(Float(value), animated: true)
        if value >= 1.0 {
            UIView.animate(withDuration: 0.25, delay: 0.15, options: .curveEaseOut) {
                self.progressView.alpha = 0
            } completion: { _ in
                self.progressView.setProgress(0, animated: false)
            }
        } else {
            progressView.alpha = 1
        }
    }

    private func updateNavigationButtons() {
        backButton.isEnabled = webView.canGoBack
        forwardButton.isEnabled = webView.canGoForward
    }

    private func updateCommentsButton() {
        let isComments = mode == .comments
        commentsButton.setImage(UIImage(systemName: isComments ? "bubble.right.fill" : "bubble.right"), for: .normal)
        commentsButton.tintColor = .label
    }

    /// The web view's own back/forward buttons move between the article and
    /// the comments page without going through the toolbar, so the button
    /// state is derived from the current URL after every navigation.
    private func syncModeWithWebViewURL() {
        guard let url = webView.url else { return }
        let isItemPage = url.host == "news.ycombinator.com" && url.path == "/item"
        mode = isItemPage ? .comments : .article
        updateCommentsButton()
    }

    // MARK: - Bottom bar entrance

    private func animateBottomBarIn() {
        guard !didAnimateBottomBar else { return }
        didAnimateBottomBar = true
        if UIAccessibility.isReduceMotionEnabled {
            bottomBar.alpha = 1
            bottomBar.transform = .identity
        } else {
            let animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 1.0)
            animator.addAnimations {
                self.bottomBar.alpha = 1
                self.bottomBar.transform = .identity
            }
            animator.startAnimation()
        }
    }

    // MARK: - Error overlay

    private func showErrorOverlay() {
        if errorOverlay == nil {
            let overlay = StoryListErrorView()
            overlay.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                overlay.topAnchor.constraint(equalTo: progressView.bottomAnchor),
                overlay.bottomAnchor.constraint(equalTo: bottomBar.topAnchor),
            ])
            errorOverlay = overlay
        }
        errorOverlay?.configure(
            message: "The page couldn't be loaded. Check your connection and try again.",
            title: "Couldn't load page"
        ) { [weak self] in
            self?.loadCurrent()
        }
        errorOverlay?.isHidden = false
    }

    private func hideErrorOverlay() {
        errorOverlay?.isHidden = true
    }

    // MARK: - Archive copy

    private func resolveArchiveButton() async {
        guard let articleURL else { return }
        guard let snapshot = await archiveChecker.latestSnapshot(for: articleURL) else { return }
        archiveSnapshotURL = snapshot
        showArchiveButton()
    }

    private func showArchiveButton() {
        archiveButton.isHidden = false
        archiveButton.alpha = 0
        if UIAccessibility.isReduceMotionEnabled {
            archiveButton.alpha = 1
        } else {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
                self.archiveButton.alpha = 1
            }
        }
    }

    @objc private func didTapArchive() {
        guard let url = archiveSnapshotURL else { return }
        hideErrorOverlay()
        webView.load(URLRequest(url: url))
    }

    // MARK: - Toolbar actions

    @objc private func didTapBack() {
        webView.goBack()
    }

    @objc private func didTapForward() {
        webView.goForward()
    }

    @objc private func didTapComments() {
        mode = mode == .comments ? .article : .comments
        // If there is no article URL, comments is the only mode.
        if mode == .article, articleURL == nil {
            mode = .comments
        }
        updateCommentsButton()
        loadCurrent()
    }

    @objc private func didTapShare() {
        guard let url = webView.url ?? currentURL as URL? else { return }
        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceView = shareButton
        activity.popoverPresentationController?.sourceRect = shareButton.bounds
        present(activity, animated: true)
    }

    @objc private func didTapSafari() {
        let url = webView.url ?? currentURL
        UIApplication.shared.open(url)
    }
}

// MARK: - WKNavigationDelegate

extension StoryDetailViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        updateNavigationButtons()
        syncModeWithWebViewURL()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationButtons()
        syncModeWithWebViewURL()
        hideErrorOverlay()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        showErrorOverlay()
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        if (error as NSError).code == NSURLErrorCancelled { return }
        showErrorOverlay()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url,
           let scheme = url.scheme,
           scheme != "http", scheme != "https",
           scheme != "about", scheme != "data", scheme != "blob",
           UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }
}

// MARK: - WKUIDelegate

extension StoryDetailViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            webView.load(URLRequest(url: url))
        }
        return nil
    }
}
