//
//  AppDelegate.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 10/21/18.
//  Copyright © 2018 Derek Walsh. All rights reserved.
//
//  This file contains the application delegate for NAWGJ Expense Tracker.
//  The AppDelegate is responsible for responding to app lifecycle events
//  such as launch, backgrounding, and termination. It is the entry point
//  for the application and sets up the main window and root view controller.
//
//  The app uses UIKit and follows the standard UIApplicationDelegate pattern.

import UIKit

/// The application delegate for NAWGJ Expense Tracker.
///
/// Handles app lifecycle events and sets up the main window and root view controller.
/// Most app-specific logic is handled in view controllers and managers.
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// The main window for the application.
    var window: UIWindow?

    /// Called after the app has launched. Override point for customization after launch.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        configureAppearance()
        return true
    }

    /// Applies the NAWGJ brand color scheme (navy + gold, sampled from
    /// nawgj.org) to the navigation bar used throughout the app, both the
    /// remaining storyboard/UIKit screens and the SwiftUI screens hosted in
    /// a `UINavigationController`. The app-wide tint (buttons, links, etc.)
    /// comes from the "AccentColor" asset automatically.
    private func configureAppearance() {
        guard let navy = UIColor(named: "NAWGJNavy") else { return }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = navy
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = .white
    }

    // MARK: UISceneSession Lifecycle

    /// Called when a new scene session is being created. Hands off UI setup to `SceneDelegate`.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user discards a scene session. Not used since this app doesn't support multiple scenes.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }

    /// Called when the app is about to move from active to inactive state.
    func applicationWillResignActive(_ application: UIApplication) {
        // Pause ongoing tasks, disable timers, etc.
    }

    /// Called when the app enters the background.
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Release shared resources, save user data, invalidate timers, etc.
    }

    /// Called as part of the transition from background to active state.
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Undo changes made on entering the background.
    }

    /// Called when the app becomes active again.
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any paused tasks, refresh UI if needed.
    }

    /// Called when the app is about to terminate.
    func applicationWillTerminate(_ application: UIApplication) {
        // Save data if appropriate.
    }
}
