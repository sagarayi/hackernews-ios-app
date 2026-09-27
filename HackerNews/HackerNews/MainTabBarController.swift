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
        viewControllers = Feed.allCases.enumerated().map { index, feed in
            let viewModel = StoryListViewModel(repo: DefaultHNRepository(), feed: feed)
            let list = StoryListViewController(viewModel: viewModel)
            list.tabBarItem = UITabBarItem(title: feed.title, image: UIImage(systemName: feed.tabIconName), tag: index)
            return UINavigationController(rootViewController: list)
        }
        configureTabBar()
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
