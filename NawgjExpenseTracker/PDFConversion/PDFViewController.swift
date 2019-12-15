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

class PDFViewController: UIViewController, MFMailComposeViewControllerDelegate, UIActivityItemSource {
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return pdfURL!
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Invoice and Details for " + MeetListManager.GetInstance().getSelectedMeet()!.name
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return pdfURL
    }

    //@IBOutlet weak var emailButton: UIBarButtonItem!
    var pdfURL : URL?
    var pdfView : PDFView?
    
    @objc func share(sender: UIView){
        //let docsurl = try! fileManager.url(for:.documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        if pdfURL != nil{
            let items = [self]
            let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
            if let popOver = ac.popoverPresentationController {
                popOver.sourceView = self.view
                popOver.sourceRect = sender.bounds
                popOver.permittedArrowDirections = []
                popOver.canOverlapSourceViewRect = true
            }
            present(ac, animated: true)
        }
    }
    
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
    
    @IBAction func shareMeetReport(_ sender: UIBarButtonItem) {
        self.share(sender: self.view)
    }
    
    /*
    func emailPDF(){
        if let path = pdfURL{
            let email = ""
            
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
    }*/
}
