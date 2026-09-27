//
//  StoryListViewController.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/17/25.
//

import UIKit

final class StoryListViewController: UIViewController {
    // MARK: - Dependencies

    private let viewModel: StoryListViewModeling

    // MARK: - Views

    private var tableView: UITableView!
    private var dataSource: UITableViewDiffableDataSource<Int, Int>!
    private let refreshControl = UIRefreshControl()

    private var skeletonView: SkeletonLoadingView?
    private var fullScreenErrorView: StoryListErrorView?
    private var errorBanner: LoadMoreErrorBanner?
    private var bannerAnimator: UIViewPropertyAnimator?

    // MARK: - Init

    init(viewModel: StoryListViewModeling? = nil) {
        self.viewModel = viewModel ?? StoryListViewModel(repo: DefaultHNRepository(), feed: .new)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — StoryListViewController is programmatic")
    }

    // MARK: - Lifecycle

    override func loadView() {
        let root = UIView()
        root.backgroundColor = HNTheme.beige
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureTableView()
        configureDataSource()
        configureRefreshControl()
        bindViewModel()
        Task { [weak self] in
            await self?.viewModel.load()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Reassert bar styling: rotation, tab switches, and returns from the
        // detail screen can otherwise leave the bar unstylized.
        configureNavigationBar()
    }

    // MARK: - Setup

    private func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = HNTheme.orange
        appearance.titleTextAttributes = [.font: HNTheme.navTitleFont, .foregroundColor: UIColor.black]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .black
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.title = viewModel.feedTitle
    }

    private func configureTableView() {
        let table = UITableView(frame: .zero, style: .plain)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = HNTheme.beige
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 72
        table.separatorStyle = .none
        table.prefetchDataSource = self
        table.delegate = self
        table.register(StoryViewCell.self, forCellReuseIdentifier: StoryViewCell.reuseIdentifier)
        table.register(HNCommentCell.self, forCellReuseIdentifier: HNCommentCell.reuseIdentifier)
        table.refreshControl = refreshControl
        view.addSubview(table)
        // Pinned to the safe area (both bars are opaque): scroll insets stay
        // constant, so push/pop transitions never shift or flash the rows.
        NSLayoutConstraint.activate([
            table.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            table.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            table.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            table.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        self.tableView = table
    }

    private func configureDataSource() {
        dataSource = UITableViewDiffableDataSource<Int, Int>(tableView: tableView) { [weak self] tableView, indexPath, storyId in
            let item = self?.viewModel.item(for: storyId)
            if item?.type == .comment {
                guard let cell = tableView.dequeueReusableCell(withIdentifier: HNCommentCell.reuseIdentifier, for: indexPath) as? HNCommentCell else {
                    return UITableViewCell()
                }
                var parentTitle: String?
                if let parent = item?.parent {
                    parentTitle = self?.viewModel.item(for: parent)?.title
                }
                cell.configure(with: item, parentTitle: parentTitle)
                return cell
            }
            guard let cell = tableView.dequeueReusableCell(withIdentifier: StoryViewCell.reuseIdentifier, for: indexPath) as? StoryViewCell else {
                return UITableViewCell()
            }
            cell.configure(with: item, rank: indexPath.row + 1)
            return cell
        }
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func configureRefreshControl() {
        refreshControl.tintColor = HNTheme.gray
        refreshControl.addTarget(self, action: #selector(didPullToRefresh), for: .valueChanged)
    }

    private func bindViewModel() {
        viewModel.onChange = { [weak self] state in
            self?.apply(state: state)
        }
        viewModel.onLoadingMoreChanged = { [weak self] loading in
            self?.setLoadingMore(loading)
        }
    }

    // MARK: - Actions

    @objc private func didPullToRefresh() {
        Task { [weak self] in
            await self?.viewModel.refresh()
        }
    }

    // MARK: - State

    private func apply(state: StoryListState) {
        let ids = viewModel.items.map(\.id)
        var snapshot = NSDiffableDataSourceSnapshot<Int, Int>()
        snapshot.appendSections([0])
        snapshot.appendItems(ids)
        dataSource.apply(snapshot, animatingDifferences: !UIAccessibility.isReduceMotionEnabled)

        switch state {
        case .idle:
            break
        case .loading:
            hideErrorBanner()
            if ids.isEmpty {
                showSkeleton()
            } else {
                hideSkeleton()
            }
        case .loaded:
            hideSkeleton()
            hideFullScreenError()
            hideErrorBanner()
        case .error(let message):
            hideSkeleton()
            if ids.isEmpty {
                hideErrorBanner()
                showFullScreenError(message: message)
            } else {
                hideFullScreenError()
                showErrorBanner(message: message)
            }
        }

        if refreshControl.isRefreshing {
            switch state {
            case .loaded, .error:
                refreshControl.endRefreshing()
            case .idle, .loading:
                break
            }
        }
    }

    // MARK: - Loading indicator

    // Floating pill instead of a table footer: appearing/disappearing never
    // changes the content size, so rows don't shift under the user's finger.
    private var loadingPill: UIView?

    private func setLoadingMore(_ loading: Bool) {
        if loading {
            if loadingPill == nil {
                let pill = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
                pill.layer.cornerRadius = 18
                pill.layer.masksToBounds = true
                pill.translatesAutoresizingMaskIntoConstraints = false

                let spinner = UIActivityIndicatorView(style: .medium)
                spinner.color = HNTheme.gray
                spinner.startAnimating()
                spinner.translatesAutoresizingMaskIntoConstraints = false

                let label = UILabel()
                label.text = "Loading more stories"
                label.font = HNTheme.metaFont
                label.adjustsFontForContentSizeCategory = true
                label.textColor = HNTheme.gray
                label.translatesAutoresizingMaskIntoConstraints = false

                let stack = UIStackView(arrangedSubviews: [spinner, label])
                stack.axis = .horizontal
                stack.spacing = 8
                stack.alignment = .center
                stack.translatesAutoresizingMaskIntoConstraints = false
                pill.contentView.addSubview(stack)
                NSLayoutConstraint.activate([
                    stack.leadingAnchor.constraint(equalTo: pill.contentView.leadingAnchor, constant: 14),
                    stack.trailingAnchor.constraint(equalTo: pill.contentView.trailingAnchor, constant: -14),
                    stack.topAnchor.constraint(equalTo: pill.contentView.topAnchor, constant: 8),
                    stack.bottomAnchor.constraint(equalTo: pill.contentView.bottomAnchor, constant: -8),
                ])

                view.addSubview(pill)
                NSLayoutConstraint.activate([
                    pill.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                    pill.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                ])
                loadingPill = pill
            }
            guard let pill = loadingPill, pill.isHidden else { return }
            pill.isHidden = false
            pill.alpha = 0
            if UIAccessibility.isReduceMotionEnabled {
                pill.alpha = 1
            } else {
                UIView.animate(withDuration: 0.2) { pill.alpha = 1 }
            }
        } else {
            loadingPill?.isHidden = true
        }
    }

    // MARK: - Skeleton

    private func showSkeleton() {
        if skeletonView == nil {
            skeletonView = SkeletonLoadingView()
        }
        tableView.backgroundView = skeletonView
    }

    private func hideSkeleton() {
        if tableView.backgroundView === skeletonView {
            tableView.backgroundView = nil
        }
    }

    // MARK: - Full-screen error

    private func showFullScreenError(message: String) {
        let errorView: StoryListErrorView
        if let existing = fullScreenErrorView {
            errorView = existing
        } else {
            errorView = StoryListErrorView()
            fullScreenErrorView = errorView
        }
        errorView.configure(message: message) { [weak self] in
            Task { [weak self] in
                await self?.viewModel.load()
            }
        }
        tableView.backgroundView = errorView
    }

    private func hideFullScreenError() {
        if tableView.backgroundView === fullScreenErrorView {
            tableView.backgroundView = nil
        }
    }

    // MARK: - Error banner

    private func showErrorBanner(message: String) {
        bannerAnimator?.stopAnimation(true)
        let banner: LoadMoreErrorBanner
        if let existing = errorBanner {
            banner = existing
        } else {
            banner = LoadMoreErrorBanner()
            errorBanner = banner
            banner.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(banner)
            NSLayoutConstraint.activate([
                banner.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                banner.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                banner.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            ])
            view.layoutIfNeeded()
        }
        banner.configure(message: message) { [weak self] in
            Task { [weak self] in
                await self?.viewModel.retryLoadMore()
            }
        }
        banner.isHidden = false
        banner.alpha = 0
        banner.transform = CGAffineTransform(translationX: 0, y: 12)
        if UIAccessibility.isReduceMotionEnabled {
            banner.alpha = 1
            banner.transform = .identity
        } else {
            bannerAnimator = UIViewPropertyAnimator(duration: 0.45, dampingRatio: 1.0)
            bannerAnimator?.addAnimations {
                banner.alpha = 1
                banner.transform = .identity
            }
            bannerAnimator?.startAnimation()
        }
    }

    private func hideErrorBanner() {
        guard let banner = errorBanner, !banner.isHidden else { return }
        bannerAnimator?.stopAnimation(true)
        if UIAccessibility.isReduceMotionEnabled {
            banner.isHidden = true
            return
        }
        bannerAnimator = UIViewPropertyAnimator(duration: 0.25, dampingRatio: 1.0)
        bannerAnimator?.addAnimations {
            banner.alpha = 0
            banner.transform = CGAffineTransform(translationX: 0, y: 8)
        }
        bannerAnimator?.addCompletion { _ in
            banner.isHidden = true
        }
        bannerAnimator?.startAnimation()
    }
}

// MARK: - UITableViewDelegate

extension StoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath),
              let item = viewModel.item(for: id) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        navigationController?.pushViewController(StoryDetailViewController(item: item), animated: true)
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        Task { [weak self] in
            await self?.viewModel.loadMoreIfNeeded(currentIndex: indexPath.row)
        }
    }
}

// MARK: - UITableViewDataSourcePrefetching

extension StoryListViewController: UITableViewDataSourcePrefetching {
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        guard let maxRow = indexPaths.map(\.row).max() else { return }
        Task { [weak self] in
            await self?.viewModel.loadMoreIfNeeded(currentIndex: maxRow)
        }
    }
}
