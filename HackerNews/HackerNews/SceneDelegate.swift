//
//  SceneDelegate.swift
//  HackerNews
//
//  Created by Sagar Ayi on 8/17/25.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainTabBarController()
        self.window = window
        window.makeKeyAndVisible()
    }
}
