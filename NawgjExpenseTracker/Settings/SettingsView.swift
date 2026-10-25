//
//  SettingsView.swift
//  NawgjExpenseTracker
//
//  App-wide user preferences. One of the app's three tab roots (Meets /
//  Judges / Settings - see SceneDelegate.swift). Currently holds a single
//  toggle controlling whether judges found in existing meets but missing
//  from the master Judge List are automatically added to it on launch (see
//  MeetListView.synchronizeJudgeList()).
//

import SwiftUI

/// Centralizes app-wide user preferences backed by `UserDefaults`.
enum AppSettings {
    static let autoAddJudgesFromMeetsKey = "autoAddJudgesFromMeetsEnabled"

    /// When enabled, judges found in existing meets but missing from the
    /// master Judge List are automatically added to it on launch (mirrors
    /// the old MeetTableViewController.synchronizeJudgeList() behavior).
    /// Defaults to off.
    static var autoAddJudgesFromMeetsEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoAddJudgesFromMeetsKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoAddJudgesFromMeetsKey) }
    }
}

struct SettingsView: View {
    @AppStorage(AppSettings.autoAddJudgesFromMeetsKey) private var autoAddJudgesFromMeetsEnabled = false

    var body: some View {
        Form {
            Section {
                Toggle("Add Judges From Meets Automatically", isOn: $autoAddJudgesFromMeetsEnabled)
            } footer: {
                Text("When on, judges found in your meets that aren't already in your Judge List are added to it automatically each time the app launches.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
