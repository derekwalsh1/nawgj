//
//  SceneDelegate.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 7/25/26.
//  Copyright © 2026 Derek Walsh. All rights reserved.
//
//  Modern UIKit scene lifecycle entry point. The app has a single window
//  scene. The root screen (Meet List) is a SwiftUI view (MeetListView),
//  hosted directly in a UINavigationController rather than instantiated
//  from the Main storyboard, which supplies pushViewController/
//  popViewController closures used to bridge into the remaining
//  UIKit/storyboard screens (same pattern used by MeetDetailView and other
//  SwiftUI screens further down the navigation stack).

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)

        let navigationController = UINavigationController()
        let meetListView = MeetListView(
            pushViewController: { [weak navigationController] viewController in
                navigationController?.pushViewController(viewController, animated: true)
            },
            popViewController: { [weak navigationController] in
                navigationController?.popViewController(animated: true)
            }
        )
        navigationController.viewControllers = [UIHostingController(rootView: meetListView)]

        window.rootViewController = navigationController
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
