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
        // Follows the system appearance; HNTheme colors adapt (beige by day,
        // warm charcoal by night, orange chrome throughout).
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
        // Settings closes the list after Jobs with the appearance switcher
        // and the About section; iOS shows the first four tabs and groups
        // the rest under More.
        let settings = UINavigationController(rootViewController: SettingsViewController())
        settings.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 100)
        viewControllers = feeds + [settings]
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

        func style(_ itemAppearance: UITabBarItemAppearance) {
            itemAppearance.normal.iconColor = HNTheme.tabUnselected
            itemAppearance.normal.titleTextAttributes = [
                .font: HNTheme.tabFont,
                .foregroundColor: HNTheme.tabUnselected,
            ]
            itemAppearance.selected.iconColor = HNTheme.tabSelected
            itemAppearance.selected.titleTextAttributes = [
                .font: HNTheme.tabFont,
                .foregroundColor: HNTheme.tabSelected,
            ]
        }
        style(appearance.stackedLayoutAppearance)
        style(appearance.inlineLayoutAppearance)
        style(appearance.compactInlineLayoutAppearance)

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        tabBar.tintColor = HNTheme.tabSelected
        tabBar.unselectedItemTintColor = HNTheme.tabUnselected
    }
}
