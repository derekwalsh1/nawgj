//
//  PDFViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek on 1/16/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log
import PDFKit
import MessageUI

class JudgePDFViewController: UIViewController, UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return pdfURL!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Invoice and Details for " + MeetListManager.GetInstance().getSelectedJudge()!.name.replacingOccurrences(of: " ", with: "_", options: .literal, range: nil)
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return pdfURL
    }

    //@IBOutlet weak var emailButton: UIBarButtonItem!
    var pdfURL : URL?
    var pdfView : PDFView?
    
    @objc func share(sender: UIView){
        if pdfURL != nil{
            let items = [self]
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            
            if let popOver = ac.popoverPresentationController {
                popOver.sourceView = self.view
                popOver.sourceRect = sender.bounds
                popOver.permittedArrowDirections = []
                popOver.canOverlapSourceViewRect = true
                //popOver.sourceRect = CGRect(x: -sender.frame.width, y: -sender.frame.height, width:sender.frame.width, height: sender.frame.height)
              //popOver.sourceRect =
              //popOver.barButtonItem
            }
            
            present(ac, animated: true, completion: nil)
            
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pdfURL = MeetListManager.DocumentsDirectory.appendingPathComponent("JudgeInvoice.pdf")
        JudgePDFCreator.createPDFFrom(judge: MeetListManager.GetInstance().getSelectedJudge()!, meet: MeetListManager.GetInstance().getSelectedMeet()!, atLocation: pdfURL!)
        
        // Add PDFView to view controller.
        pdfView = PDFView(frame: self.view.bounds)
        if let pdfView = pdfView{
            pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.view.addSubview(pdfView)
            
            // Load Sample.pdf file from app bundle.
            pdfView.document = PDFDocument(url: pdfURL!)
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.displayMode = .singlePageContinuous
            pdfView.pageBreakMargins = UIEdgeInsets(top: 20, left: 20, bottom: 200, right: 20)
            pdfView.displaysPageBreaks = true
            pdfView.layoutMargins = UIEdgeInsets(top: 40, left: 40, bottom: 50, right: 40)
        }
    }
    
    @IBAction func shareMeetReport(_ sender: UIBarButtonItem) {
        self.share(sender: self.view)
    }
}
