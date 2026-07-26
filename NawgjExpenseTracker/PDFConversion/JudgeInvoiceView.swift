//
//  JudgeInvoiceView.swift
//  NawgjExpenseTracker
//
//  SwiftUI replacement for the old storyboard-driven "Invoice" screen
//  (formerly JudgePDFViewController), pushed from MeetJudgeDetailView's
//  "Invoice" toolbar button. Generates the per-judge invoice PDF (via
//  JudgePDFCreator, unchanged) and displays/shares it.
//
//  Phase 4 of the incremental SwiftUI migration - see
//  .github/MODERNIZATION_BACKLOG.md.
//

import SwiftUI
import PDFKit

struct JudgeInvoiceView: View {

    let judge: Judge
    let meet: Meet

    init(judge: Judge, meet: Meet) {
        self.judge = judge
        self.meet = meet
    }

    @State private var pdfURL: URL?
    @State private var isShareSheetPresented = false

    var body: some View {
        Group {
            if let pdfURL {
                PDFKitRepresentedView(url: pdfURL)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Invoice")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShareSheetPresented = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(pdfURL == nil)
            }
        }
        .sheet(isPresented: $isShareSheetPresented) {
            if let pdfURL {
                ActivityView(activityItemSource: PDFActivityItemSource(url: pdfURL, subject: shareSubject))
            }
        }
        .onAppear {
            generatePDFIfNeeded()
        }
    }

    private var shareSubject: String {
        "Invoice and Details for " + judge.name.replacingOccurrences(of: " ", with: "_", options: .literal, range: nil)
    }

    private func generatePDFIfNeeded() {
        guard pdfURL == nil else { return }
        let url = MeetListManager.DocumentsDirectory.appendingPathComponent("JudgeInvoice.pdf")
        JudgePDFCreator.createPDFFrom(judge: judge, meet: meet, atLocation: url)
        pdfURL = url
    }
}

/// Wraps a PDFKit `PDFView` for display inside SwiftUI, matching the
/// display settings used by the old `JudgePDFViewController`.
private struct PDFKitRepresentedView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayDirection = .vertical
        pdfView.displayMode = .singlePageContinuous
        pdfView.pageBreakMargins = UIEdgeInsets(top: 20, left: 20, bottom: 200, right: 20)
        pdfView.displaysPageBreaks = true
        pdfView.layoutMargins = UIEdgeInsets(top: 40, left: 40, bottom: 50, right: 40)
        pdfView.document = PDFDocument(url: url)
        return pdfView
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document?.documentURL != url {
            uiView.document = PDFDocument(url: url)
        }
    }
}

/// Provides the PDF file and a custom email subject line to the share sheet,
/// matching the old `JudgePDFViewController`'s `UIActivityItemSource`
/// conformance.
private final class PDFActivityItemSource: NSObject, UIActivityItemSource {
    let url: URL
    let subject: String

    init(url: URL, subject: String) {
        self.url = url
        self.subject = subject
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        url
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        subject
    }
}

/// Generic SwiftUI wrapper around `UIActivityViewController` for sharing a
/// single `UIActivityItemSource`.
private struct ActivityView: UIViewControllerRepresentable {
    let activityItemSource: UIActivityItemSource

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [activityItemSource], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
