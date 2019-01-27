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

class PDFViewController: UIViewController, MFMailComposeViewControllerDelegate {

    @IBOutlet weak var emailButton: UIBarButtonItem!
    var pdfURL : URL?
    var pdfView : PDFView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pdfURL = MeetListManager.DocumentsDirectory.appendingPathComponent("MeetDetails.pdf")
        MeetPDFCreator.createPDFFrom(meet: MeetListManager.GetInstance().getSelectedMeet()!, atLocation: pdfURL!)
        
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
    
    @IBAction func shareButtonClicked(_ sender: Any) {
        emailPDF()
    }
    
    func emailPDF(){
        if let path = pdfURL{
            let email = "derek.walsh@gmail.com"
            
            if( MFMailComposeViewController.canSendMail()){
                let mailComposer = MFMailComposeViewController()
                mailComposer.mailComposeDelegate = self
                
                mailComposer.setToRecipients([email])
                mailComposer.setSubject("Meet Details for \(MeetListManager.GetInstance().getSelectedMeet()!.name)")
                mailComposer.setMessageBody("Meet details attached", isHTML: false)
                
                try! mailComposer.addAttachmentData(NSData(contentsOf: path) as Data, mimeType: "application/pdf", fileName: "MeetReport.pdf")
                self.navigationController?.present(mailComposer, animated: true, completion: nil)
            }
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func print(sender: UIBarButtonItem) {
        if let url = pdfURL{
            if UIPrintInteractionController.canPrint(url) {
                let printInfo = UIPrintInfo(dictionary: nil)
                printInfo.jobName = url.lastPathComponent
                printInfo.outputType = .grayscale
                
                let printController = UIPrintInteractionController.shared
                printController.printInfo = printInfo
                printController.showsNumberOfCopies = false
                printController.printingItem = url
                printController.present(animated: true, completionHandler: nil)
            }
        }
    }
}
