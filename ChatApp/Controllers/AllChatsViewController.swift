//
//  AllChatsViewController.swift
//  ChatApp
//
//  Created by Kashif Rizwan on 8/21/19.
//  Copyright © 2019 Dima Nikolaev. All rights reserved.
//

import UIKit
import Firebase

class AllChatsViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,prepareNewChat {
    func fillFields(rid: String, rName: String, performSegue: Bool) {
        self.rid = rid
        self.rName = rName
        self.performSegue = true
    }
    
    @IBOutlet weak var chatsTableView: UITableView!
    
    var getChatsObj = user_activity()
    private var msg = "Loading..."
    private var chatDataList:[message]!
    private var uid = Auth.auth().currentUser?.uid
    private var selectedUser:user!
    private var rid:String!
    private var rName:String!
    var performSegue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.chatsTableView.delegate = self
        self.chatsTableView.dataSource = self
        self.chatsTableView.rowHeight = UITableView.automaticDimension
        self.chatListner()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if performSegue{
            self.performSegue(withIdentifier: "toMessages", sender: nil)
            self.performSegue = false
        }
    }
    
    @IBAction func toNewChat(_ sender: Any) {
        self.performSegue(withIdentifier: "toNewChat", sender: nil)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell") as! chatsTableViewCell
        if self.chatDataList[indexPath.row].sid == uid {
            cell.name.text = self.chatDataList[indexPath.row].rName
        }else{
            cell.name.text = self.chatDataList[indexPath.row].sName
        }
        cell.date.text = staticLinker.getPastTime(for: staticLinker.getPastStatus(date: self.chatDataList[indexPath.row].date).0)
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
        var chatId = String()
        if segue.identifier == "toMessages"{
            let messagesVC = segue.destination as! chatViewController
            if self.uid! > self.rid{
                chatId = self.uid! + self.rid
            }else{
                chatId = self.rid + self.uid!
            }
            messagesVC.chatId = chatId
            messagesVC.recvName = self.rName
            messagesVC.recvId = self.rid
        }else if segue.identifier == "toNewChat"{
            let selectUserVC = segue.destination as! selectUserViewController
            selectUserVC.fillNewChatDel = self
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.chatDataList![indexPath.row].rid == self.uid{
            self.rName = self.chatDataList[indexPath.row].sName
            self.rid = self.chatDataList![indexPath.row].sid
        }else{
            self.rName = self.chatDataList[indexPath.row].rName
            self.rid = self.chatDataList[indexPath.row].rid
        }
        self.performSegue(withIdentifier: "toMessages", sender: nil)
        self.chatsTableView.deselectRow(at: indexPath, animated: true)
    }
}
