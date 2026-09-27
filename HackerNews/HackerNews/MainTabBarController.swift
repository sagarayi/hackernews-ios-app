//
//  MainTabBarController.swift
//  HackerNews
//
//  Tabs mirror the news.ycombinator.com navigation. Submit is omitted
//  because posting requires a logged-in account.
//

import UIKit

final class MainTabBarController: UITabBarController {
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported — MainTabBarController is programmatic")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // The website is light-only; pin the whole app to match.
        overrideUserInterfaceStyle = .light
        view.backgroundColor = HNTheme.beige
        // One shared repository: its item cache is then shared across tabs,
        // so switching tabs and retrying pages reuses fetched items
        // instead of refetching them.
        let repository = DefaultHNRepository()
        let feeds: [UIViewController] = Feed.allCases.enumerated().map { index, feed in
            let viewModel = StoryListViewModel(repo: repository, feed: feed)
            let list = StoryListViewController(viewModel: viewModel)
            list.tabBarItem = UITabBarItem(title: feed.title, image: UIImage(systemName: feed.tabIconName), tag: index)
            return UINavigationController(rootViewController: list)
        }
        // About closes the list after Jobs; iOS shows the first four tabs
        // and groups the rest under More.
        let about = UINavigationController(rootViewController: AboutViewController(showsDoneButton: false))
        about.tabBarItem = UITabBarItem(title: "About", image: UIImage(systemName: "info.circle"), tag: 100)
        viewControllers = feeds + [about]
        configureGlobalBarAppearance()
        configureTabBar()
        configureMoreController()
    }

    private func configureGlobalBarAppearance() {
        // Single source for every navigation bar (feed tabs, About tab, the
        // system More controller, pushed screens): opaque orange, black text.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = HNTheme.orange
        appearance.titleTextAttributes = [.font: HNTheme.navTitleFont, .foregroundColor: UIColor.black]
        let proxy = UINavigationBar.appearance()
        proxy.standardAppearance = appearance
        proxy.scrollEdgeAppearance = appearance
        proxy.compactAppearance = appearance
        proxy.tintColor = .black
    }

    private func configureMoreController() {
        // The system More screen (holding Show, Jobs, and About) only needs
        // matching bar chrome.
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = HNTheme.orange
        appearance.titleTextAttributes = [.font: HNTheme.navTitleFont, .foregroundColor: UIColor.black]
        let bar = moreNavigationController.navigationBar
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.compactAppearance = appearance
        bar.tintColor = .black
        bar.prefersLargeTitles = false

    }

    private func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = HNTheme.orange

        let normalColor = UIColor.black.withAlphaComponent(0.55)
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .font: HNTheme.tabFont,
            .foregroundColor: normalColor,
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .black
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .font: HNTheme.tabFont,
            .foregroundColor: UIColor.black,
        ]

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = .black
        tabBar.unselectedItemTintColor = normalColor
    }
}
