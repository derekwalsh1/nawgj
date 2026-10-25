//
//  SceneDelegate.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 7/25/26.
//  Copyright © 2026 Derek Walsh. All rights reserved.
//
//  Modern UIKit scene lifecycle entry point. The app has a single window
//  scene, rooted in a UITabBarController with three tabs - Meets, Judges,
//  Settings - each its own UINavigationController hosting a SwiftUI root
//  view. A persistent, labeled bottom tab bar (rather than nav-bar icon
//  buttons) was chosen for clarity: it's the most familiar iOS navigation
//  pattern, every destination is always visible with a text label (not
//  just an icon to decode), and it's one tap away with no hidden menus -
//  important for an audience that may not be deeply familiar with newer
//  iOS UI conventions. Each tab's SwiftUI root view is supplied its own
//  pushViewController/popViewController closures, bound to that tab's own
//  navigation controller, used to bridge into the remaining UIKit/
//  storyboard screens further down each tab's stack (same pattern used by
//  MeetDetailView and other SwiftUI screens).

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let meetsNavigationController = UINavigationController()
        let meetListView = MeetListView(
            pushViewController: { [weak meetsNavigationController] viewController in
                meetsNavigationController?.pushViewController(viewController, animated: true)
            },
            popViewController: { [weak meetsNavigationController] in
                meetsNavigationController?.popViewController(animated: true)
            }
        )
        meetsNavigationController.viewControllers = [UIHostingController(rootView: meetListView)]
        meetsNavigationController.tabBarItem = UITabBarItem(title: "Meets", image: UIImage(systemName: "calendar"), selectedImage: nil)

        let judgesNavigationController = UINavigationController()
        let judgeListView = JudgeListView(
            pushViewController: { [weak judgesNavigationController] viewController in
                judgesNavigationController?.pushViewController(viewController, animated: true)
            },
            popViewController: { [weak judgesNavigationController] in
                judgesNavigationController?.popViewController(animated: true)
            }
        )
        judgesNavigationController.viewControllers = [UIHostingController(rootView: judgeListView)]
        judgesNavigationController.tabBarItem = UITabBarItem(title: "Judges", image: UIImage(systemName: "person.2"), selectedImage: nil)

        let settingsNavigationController = UINavigationController()
        settingsNavigationController.viewControllers = [UIHostingController(rootView: SettingsView())]
        settingsNavigationController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), selectedImage: nil)

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [meetsNavigationController, judgesNavigationController, settingsNavigationController]

        window.rootViewController = tabBarController
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}
