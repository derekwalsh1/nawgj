//
//  MeetTableImportExportCell.swift
//  NawgjExpenseTracker
//
//  Created by Derek Walsh on 2/21/23.
//  Copyright © 2023 Derek Walsh. All rights reserved.
//

import os.log
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class MeetTableImportExportCell: UITableViewCell, UIDocumentPickerDelegate {
    
    //MARK: Properties
    var numberFormatter : NumberFormatter = NumberFormatter()
    var dateFormatter : DateFormatter = DateFormatter()
    
    var parentViewController : UITableViewController?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        numberFormatter.numberStyle = .currency
        dateFormatter.dateStyle = .short
        
        setupCellContent()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func importMeetButtonTouched(_ sender: UIButton) {
        var documentPicker: UIDocumentPickerViewController
        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType] = [UTType.json]
            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            documentPicker = UIDocumentPickerViewController(documentTypes: ["public.json"], in: UIDocumentPickerMode.import)
        }
        documentPicker.delegate = self
        self.parentViewController?.present(documentPicker, animated: true, completion: nil)
    }
    
    @available(iOS 11.0, *)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]){
        
        if let jsonFile = urls.first{
            guard jsonFile.startAccessingSecurityScopedResource() else {
                os_log("Failed permission to access meet...", log: OSLog.default, type: .error)
                return
            }
            defer { jsonFile.stopAccessingSecurityScopedResource() }
            do {
                //let text = try String(contentsOf: jsonFile, encoding: .utf8)
                let data:Data = try Data(contentsOf: jsonFile)
                let jsonDecoder = JSONDecoder()
                let importedMeet = try jsonDecoder.decode(Meet.self, from: data) as Meet
                
                MeetListManager.GetInstance().addMeet(meet: importedMeet)
                os_log("Successfully imported meet: %{public}@", log: OSLog.default, type: .info, importedMeet.name)
            }
            catch let DecodingError.dataCorrupted(context) {
                os_log("Data corrupted: %{public}@", log: OSLog.default, type: .error, context.debugDescription)
            }
            catch let DecodingError.keyNotFound(key, context) {
                os_log("Key '%{public}@' not found: %{public}@", log: OSLog.default, type: .error, key.stringValue, context.debugDescription)
            }
            catch let DecodingError.valueNotFound(value, context) {
                os_log("Value '%{public}@' not found: %{public}@", log: OSLog.default, type: .error, String(describing: value), context.debugDescription)
            }
            catch let DecodingError.typeMismatch(type, context) {
                os_log("Type '%{public}@' mismatch: %{public}@", log: OSLog.default, type: .error, String(describing: type), context.debugDescription)
            }
            catch {
                os_log("Failed to import meet: %{public}@", log: OSLog.default, type: .error, error.localizedDescription)
            }
        }
        self.parentViewController?.tableView.reloadData()
    }
    
    // called if the user dismisses the document picker without selecting a document (using the Cancel button)
    @available(iOS 8.0, *)
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController){
        
    }
    
    @available(iOS, introduced: 8.0, deprecated: 11.0)
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL)
    {
        MeetListManager.GetInstance().importMeet(fromFile: url)
    }
    
    func setupCellContent(){
        
    }
}
