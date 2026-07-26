//
//  SwiftUIHosting.swift
//  NawgjExpenceTracker
//
//  Created by Derek on 7/25/26.
//  Copyright © 2026 Derek Walsh. All rights reserved.
//
//  Small helper for bridging SwiftUI screens into the existing storyboard-
//  driven, UIKit navigation flow. As screens are rewritten in SwiftUI
//  (see .github/MODERNIZATION_BACKLOG.md), wrap them in a `UIHostingController`
//  and push/present them from the existing view controllers using the helpers
//  below, instead of hand-rolling a `UIHostingController` at every call site.

import SwiftUI
import UIKit

extension UIViewController {

    /// Wraps `view` in a `UIHostingController` and pushes it onto this view
    /// controller's navigation stack, the SwiftUI equivalent of a storyboard
    /// "show" segue.
    ///
    /// - Returns: The `UIHostingController` that was pushed, in case the
    ///   caller needs to hold onto it (e.g. to update `rootView` later).
    @discardableResult
    func pushSwiftUIView<Content: View>(_ view: Content, animated: Bool = true) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: view)
        navigationController?.pushViewController(hostingController, animated: animated)
        return hostingController
    }

    /// Wraps `view` in a `UIHostingController` and presents it modally over
    /// this view controller, the SwiftUI equivalent of a storyboard "present
    /// modally" segue.
    @discardableResult
    func presentSwiftUIView<Content: View>(_ view: Content, animated: Bool = true, completion: (() -> Void)? = nil) -> UIHostingController<Content> {
        let hostingController = UIHostingController(rootView: view)
        present(hostingController, animated: animated, completion: completion)
        return hostingController
    }
}
