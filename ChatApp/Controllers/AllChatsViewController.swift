//
//  AllChatsViewController.swift
//  ChatApp
//
//  Created by Kashif Rizwan on 8/21/19.
//  Copyright © 2019 Dima Nikolaev. All rights reserved.
//

import UIKit
import Firebase

class AllChatsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var chatsTableView: UITableView!
    
    var getChatsObj = user_activity()
    private var msg = "Loading..."
    private var chatDataList:[message]!
    private var uid = Auth.auth().currentUser?.uid
    private var selectedIndex = -1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chatsTableView.delegate = self
        self.chatsTableView.dataSource = self
        self.chatsTableView.rowHeight = UITableView.automaticDimension
        self.chatListner()
    }
    
    func chatListner(){
        getChatsObj.getAllChats(completion: {(error, msgs) in
            DispatchQueue.main.async {
                if let err = error{
                    self.msg = err
                    self.chatDataList = nil
                    self.chatsTableView.reloadData()
                }else{
                    if msgs != nil{
                        self.chatDataList = msgs
                        self.chatsTableView.reloadData()
                    }else{
                        self.msg = "No Chats"
                        self.chatDataList = nil
                        self.chatsTableView.reloadData()
                    }
                }
            }
        })
    }
    
}

extension AllChatsViewController{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myDateFormatter = DateFormatter()
        myDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        print(self.chatDataList[indexPath.row].date)
        let d = myDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(self.chatDataList[indexPath.row].date) as! TimeInterval))
        let date = myDateFormatter.date(from: d)
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as! chatsTableViewCell
        if self.chatDataList[indexPath.row].sid == uid {
            cell.name.text = self.chatDataList[indexPath.row].rName
        }else{
            cell.name.text = self.chatDataList[indexPath.row].sName
        }
        cell.date.text = self.getPastTime(for: date!)
        if self.chatDataList[indexPath.row].type == "txt"{
            cell.content.text = self.chatDataList[indexPath.row].message
        }else{
            cell.content.text = "📷 Photo"
        }
        
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSection: NSInteger = 0
        
        if self.chatDataList != nil {
            self.chatsTableView.tableFooterView = UIView()
            numOfSection = 1
        } else {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.chatsTableView.bounds.size.width, height: self.chatsTableView.bounds.size.height))
            noDataLabel.text = msg
            noDataLabel.textColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            noDataLabel.textAlignment = NSTextAlignment.center
            self.chatsTableView.tableFooterView = noDataLabel
        }
        return numOfSection
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMessages"{
            let messagesVC = segue.destination as! chatViewController
            var chatId = String()
            if self.chatDataList[self.selectedIndex].sid > self.chatDataList[self.selectedIndex].rid{
                chatId = self.chatDataList[self.selectedIndex].sid + self.chatDataList[self.selectedIndex].rid
            }else{
                chatId = self.chatDataList[self.selectedIndex].rid + self.chatDataList[self.selectedIndex].sid
            }
            messagesVC.chatId = chatId
            if self.chatDataList[self.selectedIndex].rid == self.uid{
                messagesVC.recvName = self.chatDataList[self.selectedIndex].sName
                messagesVC.recvId = self.chatDataList[self.selectedIndex].sid
            }else{
                messagesVC.recvName = self.chatDataList[self.selectedIndex].rName
                messagesVC.recvId = self.chatDataList[self.selectedIndex].rid
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath.row
        self.performSegue(withIdentifier: "toMessages", sender: nil)
        self.chatsTableView.deselectRow(at: indexPath, animated: true)
    }
    
    func getPastTime(for date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        
        if secondsAgo < minute || secondsAgo < hour || secondsAgo < day{
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            formatter.locale = Locale(identifier: "en_PK")
            let strDate: String = formatter.string(from: date)
            return strDate
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_PK")
            let strDate: String = formatter.string(from: date)
            return strDate
        }
    }
}
