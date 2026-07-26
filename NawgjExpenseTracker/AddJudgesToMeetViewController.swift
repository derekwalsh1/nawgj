//
//  AddJudgesToMeetViewController.swift
//  NawgjExpenseTracker
//
//  Created by Derek Walsh on 11/5/19.
//  Copyright © 2019 Derek Walsh. All rights reserved.
//

import UIKit
import os.log
import SwiftUI

class AddJudgesToMeetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var addNewJudgeButton: UIButton!
    @IBOutlet weak var judgeTableView: UITableView!
    
    var judgeList : [JudgeInfo] = []
    var meetJudges : [JudgeInfo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadJudgeList()
        loadMeetJudges()
        
        judgeTableView.delegate = self
        judgeTableView.dataSource = self
        judgeTableView.allowsMultipleSelection = true
        judgeTableView.allowsSelectionDuringEditing = true

        addNewJudgeButton.addTarget(self, action: #selector(createNewJudgeButtonTapped), for: .touchUpInside)
    }

    /// Presents the SwiftUI `CreateJudgeView` in place of the old
    /// storyboard-driven "Create Judge" screen/segue.
    @objc func createNewJudgeButtonTapped() {
        let createJudgeView = CreateJudgeView(mode: .create) { [weak self] in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
            // Reload the table view. Technically we would only need to do
            // this when the user actually added a judge, however for
            // simplicity, we just update/refresh the table every time,
            // mirroring the old unwindToSelectJudges behavior.
            self.loadJudgeList()
            self.judgeTableView.reloadData()
        }
        pushSwiftUIView(createJudgeView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return judgeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "JudgeInfoCell"){
            let judgeInfo = judgeList[indexPath.row]
            cell.textLabel?.text = judgeInfo.name
            cell.detailTextLabel?.text = judgeInfo.level.fullDescription
            
            if meetJudges.contains(where: {$0.name == judgeInfo.name }) {
                cell.isUserInteractionEnabled = false
                cell.detailTextLabel?.isEnabled = false
                cell.textLabel?.isEnabled = false
                cell.textLabel?.text?.append(" (Already Included)")
            }
            else{
                cell.isUserInteractionEnabled = true
                cell.detailTextLabel?.isEnabled = true
                cell.textLabel?.isEnabled = true
            }
            return cell
        }
        else{
            return UITableViewCell()
        }
        
    }
    
    func loadJudgeList(){
        JudgeListManager.GetInstance().loadAndSortJudges()
        if let allJudges = JudgeListManager.GetInstance().judges{
            judgeList = allJudges
        }
        else{
            judgeList = []
        }
    }
    
    func loadMeetJudges(){
        if let meet = MeetListManager.GetInstance().getSelectedMeet(){
            
            for judge in meet.judges {
                meetJudges.append(JudgeInfo(name: judge.name, level: judge.level))
            }
        }
    }
    @IBAction func doneButtonSelected(_ sender: UIBarButtonItem) {
        
        if let selectedJudges = judgeTableView.indexPathsForSelectedRows{
            for judgeIndex in selectedJudges {
                let judgeInfo = judgeList[judgeIndex.row]
                let newJudge = Judge(name: judgeInfo.name, level: judgeInfo.level, fees: Array<Fee>())!
                
                MeetListManager.GetInstance().addJudge(judge: newJudge)
            }
        }
        
        self.performSegue(withIdentifier: "unwindToJudgeList", sender: self)
    }
    @IBAction func cancelButtonSelected(_ sender: UIBarButtonItem) {
        self.performSegue(withIdentifier: "unwindToJudgeList", sender: self)
    }
}

class CheckableTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        self.accessoryType = selected ? .checkmark : .none
    }
}
