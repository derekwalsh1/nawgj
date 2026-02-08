//
//  MeetUIPrintPageRender.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit

/// A `UIPrintPageRenderer` subclass that renders a footer for judge reports.
///
/// The renderer stores the report date, the `Judge` model to render the judge's
/// name in the footer, and the meet name. It draws a centered footer on each
/// page containing the judge name, meet name, formatted report date and the
/// page number ("Page X of Y").
///
/// Usage:
/// - Initialize with the report `date`, the `judge` model and the `meetName`.
/// - Attach this renderer to a `UIPrintInteractionController` or use it when
///   creating a PDF context.
class JudgeUIPrintPageRender: UIPrintPageRenderer {
    /// The report date used in the footer.
    var date: Date

    /// The judge model whose name will be shown in the footer.
    var judge: Judge

    /// The name of the meet to show in the footer.
    var meetName: String

    /// Date formatter used to format the `date` in the footer.
    /// Configured to the short date style by default.
    var dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .short
        return df
    }()

    /// Create a page renderer for a judge report.
    ///
    /// - Parameters:
    ///   - date: The report date to display in the footer.
    ///   - judge: The `Judge` model (used for the judge's name).
    ///   - name: The meet name to display in the footer.
    init(date: Date, judge: Judge, name: String) {
        self.date = date
        self.judge = judge
        self.meetName = name

        super.init()
    }

    /// Draws the footer for a page inside `footerRect`.
    ///
    /// The footer is horizontally centered and vertically centered within the
    /// provided `footerRect`. The text includes the judge name, meet name,
    /// formatted date, and the current page number out of the total pages.
    override func drawFooterForPage(at pageIndex: Int, in footerRect: CGRect) {
        let footerText = "\(judge.name) | Meet: \(meetName) | Report Date: \(dateFormatter.string(from: date)) | Page \(pageIndex + 1) of \(self.numberOfPages)"

        // Use the preferred font for footnote so users with larger accessibility
        // text sizes get an appropriately sized footer.
        let font = UIFont.preferredFont(forTextStyle: .footnote)

        // Paragraph style centers the text and enables truncation when the text
        // is wider than the available footer rect.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineBreakMode = .byTruncatingTail

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]

        let nsFooter = NSString(string: footerText)

        // Reserve a small horizontal padding so text doesn't touch page edges.
        let horizontalPadding: CGFloat = 8.0
        let maxWidth = max(0, footerRect.width - horizontalPadding * 2)

        // Calculate the bounding size for the text constrained to the footer's width.
        let bounding = nsFooter.boundingRect(
            with: CGSize(width: maxWidth, height: footerRect.height),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        // Use the computed size (width <= maxWidth) and center it within footerRect.
        let drawWidth = min(ceil(bounding.width), maxWidth)
        let drawHeight = ceil(bounding.height)

        let drawX = footerRect.midX - drawWidth / 2.0
        let drawY = footerRect.midY - drawHeight / 2.0

        let drawRect = CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight)

        // Draw the text inside the rect; paragraph style will center and truncate as needed.
        nsFooter.draw(in: drawRect, withAttributes: attributes)
    }
}
