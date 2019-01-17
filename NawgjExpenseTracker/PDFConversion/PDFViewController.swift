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

class PDFViewController: UIViewController {

    var pdfURL : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add PDFView to view controller.
        let pdfView = PDFView(frame: self.view.bounds)
        pdfView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.view.addSubview(pdfView)
        
        // Load Sample.pdf file from app bundle.
        if pdfURL != nil{
            pdfView.document = PDFDocument(url: pdfURL!)
            pdfView.autoScales = true
            pdfView.displayDirection = .vertical
            pdfView.displayMode = .singlePageContinuous
            pdfView.pageBreakMargins = UIEdgeInsets(top: 20, left: 20, bottom: 200, right: 20)
            pdfView.displaysPageBreaks = true
            pdfView.layoutMargins = UIEdgeInsets(top: 40, left: 40, bottom: 50, right: 40)
        }
    }
}
