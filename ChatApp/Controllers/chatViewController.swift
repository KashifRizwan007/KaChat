//
//  ViewController.swift
//  ChatBubbleAdvanced
//
//  Created by Dima on 3/10/18.
//  Copyright © 2018 Dima Nikolaev. All rights reserved.
//

import UIKit
import Firebase
import IQKeyboardManager
import GrowingTextView

class chatViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    let uName = Auth.auth().currentUser?.displayName
    var recvId:String!
    var recvName:String!
    var msgs = [message]()
    private var msg = "Loading..."
    var lastDocumentSnapshot: DocumentSnapshot!
    var fetchingMore = false
    var chatId:String!
    @IBOutlet weak var messageField: GrowingTextView!
    private var userActivityObj = user_activity()
    @IBOutlet weak var containerView: UIView!
    private let refreshControl = UIRefreshControl()
    private var bringMore = false
    private var selectedIndex:IndexPath!
    private var initiate = false
    
    @IBOutlet weak var messageTableView: UITableView!
    var cellHeight:CGFloat!
    var bottomConstraint: NSLayoutConstraint?
    
    override func viewWillDisappear(_ animated: Bool) {
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        IQKeyboardManager.shared().isEnabled = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        IQKeyboardManager.shared().isEnabled = false
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        self.configureUI()
    }
    private func configureUI(){
        self.messageTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.messageTableView.refreshControl = self.refreshControl
        self.messageTableView.estimatedRowHeight = 100
        self.refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
        self.chatListner()
        bottomConstraint = NSLayoutConstraint(item: containerView!, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint!)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardNotification), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func handleKeyboardNotification(notification: NSNotification){
        if let userInfo = notification.userInfo{
            let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
            let isKeyboardShowing = notification.name == UIResponder.keyboardWillShowNotification
            if UIDevice().userInterfaceIdiom == .phone {
                switch UIScreen.main.nativeBounds.height {
                case 2436, 2688, 1792:
                    bottomConstraint?.constant = isKeyboardShowing ? -keyboardFrame.height + self.view.safeAreaInsets.bottom : 0
                default:
                    bottomConstraint?.constant = isKeyboardShowing ? -keyboardFrame.height : 0
                }
            }
            UIView.animate(withDuration: 0, delay: 0, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: {(completed) in
                if isKeyboardShowing{
                    if self.msgs.count != 0 {
                        let indexPath = IndexPath(item: self.msgs.count - 1, section: 0)
                        self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                    }
                }
            })
        }
    }
   
    @IBAction func sendMessageBtn(_ sender: Any) {
        if let m = self.messageField.text{
            let date = String(Date().timeIntervalSince1970)
            let msg = message(date: date, message: m, rDel: "false", rid: recvId, rName: recvName, sDel: "false", sid: uid!, sName: uName!, type: "txt", messageId: "", chatId: chatId)
            //self.msgs.append(msg)
            //self.messageTableView.beginUpdates()
            //self.messageTableView.insertRows(at: [IndexPath.init(row: self.msgs.count - 1, section: 0)], with: .automatic)
            //self.messageTableView.endUpdates()
//            let indexPath = IndexPath(item: self.msgs.count - 1, section: 0)
//            self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            self.userActivityObj.sendMessage(formattedDate: date, sid: self.uid!, rid: recvId!, sName: uName!, rName: recvName!, _message: m, completion: {(error,msg) in
                if let err = error{
                    print(err)
                }else if let m = msg{
                    if let index = self.msgs.firstIndex(where: {$0.date == m.date}){
                        print("isfbvisnvos")
                        self.msgs[index].messageId = m.messageId
                    }
                }
            })
        }
    }
    @objc func loadData(){
        self.refreshControl.beginRefreshing()
        self.bringMoreMessages()
    }
}
extension chatViewController{
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSection: NSInteger = 0
        
        if self.msgs.count != 0 {
            self.messageTableView.tableFooterView = UIView()
            numOfSection = 1
        } else {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.messageTableView.bounds.size.width, height: self.messageTableView.bounds.size.height))
            noDataLabel.text = self.msg
            noDataLabel.textColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
            noDataLabel.textAlignment = NSTextAlignment.center
            self.messageTableView.tableFooterView = noDataLabel
        }
        return numOfSection
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        self.messageTableView.beginUpdates()
        self.messageTableView.endUpdates()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let myDateFormatter = DateFormatter()
        myDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZ"
        let d = myDateFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(self.msgs[indexPath.row].date) as! TimeInterval))
        let date = myDateFormatter.date(from: d)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        let dateString = dateFormatter.string(from: date!)
        
        if msgs[indexPath.row].sid == uid{
            if "pic" == msgs[indexPath.row].type {
                let cell = tableView.dequeueReusableCell(withIdentifier: "outgoingPic") as! messageBubbleIncomingPictureCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                cell.date.text = dateString
                cell.status.text = self.getPastTime(for: date!)
                cell.showIncomingMessage(cellWidth: self.view.bounds.width)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "outgoing") as! messageBubbleIncomingCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                let msg = msgs[indexPath.row].message
                cell.date.text = dateString
                cell.status.text = self.getPastTime(for: date!)
                cell.message.text = msg
                cell.message.textColor = .black
                cell.showIncomingMessage(text: msg, cellWidth: self.view.bounds.width)
                return cell
            }
        }else{
            if "pic" == msgs[indexPath.row].type {
                let cell = tableView.dequeueReusableCell(withIdentifier: "incomingPic") as! messageBubbleIncomingPictureCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                cell.date.text = dateString
                cell.status.text = self.getPastTime(for: date!)
                cell.showIncomingMessage(cellWidth: self.view.bounds.width)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "incoming") as! messageBubbleOutgoingCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                let msg = msgs[indexPath.row].message
                cell.date.text = dateString
                cell.status.text = self.getPastTime(for: date!)
                cell.message.text = msg
                cell.showOutgoingMessage(text: msg, cellWidth: self.view.bounds.width)
                return cell
            }
        }
    }
}
extension chatViewController{
    
    func chatListner(){
        db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).limit(to: 5).addSnapshotListener({(snapshot, err) in
            if let err = err {
                let alert = UIAlertController(title: "Alert", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                var temp:messageCodable
                for documents in snapshot!.documents{
                    let jsonData = try! JSONSerialization.data(withJSONObject: documents.data(), options: JSONSerialization.WritingOptions.prettyPrinted)
                    let decoder = JSONDecoder()
                    do
                    {
                        print("devdevsdwsvdf")
                        temp = try decoder.decode(messageCodable.self, from: jsonData)
                        if (temp.sid == self.uid && temp.sDel == "false") || (temp.rid == self.uid && temp.rDel == "false"){
                            let newMsg = message(date: temp.date!, message: temp.message!, rDel: temp.rDel!, rid: temp.rid!, rName: temp.rName!, sDel: temp.sDel!, sid: temp.sid!, sName: temp.sName!, type: temp.type!, messageId: documents.documentID, chatId: temp.chatId!)
                            if !self.msgs.contains(where: {$0.date == newMsg.date}){
                                if self.initiate == false{
                                    self.msgs.insert(newMsg,at: 0)
                                } else{
                                    self.msgs.append(newMsg)
                                    self.messageTableView.beginUpdates()
                                    self.messageTableView.insertRows(at: [IndexPath.init(row: self.msgs.count - 1, section: 0)], with: .automatic)
                                    self.messageTableView.endUpdates()
                                }
                            }
                        }
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                }
                if self.initiate == false{
                    self.messageTableView.reloadData()
                    self.lastDocumentSnapshot = snapshot!.documents.last
                    self.initiate = true
                }else{
                    let indexPath = IndexPath(item: self.msgs.count - 1, section: 0)
                    self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        })
    }
    
    func bringMoreMessages(){
        db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).start(afterDocument: lastDocumentSnapshot).limit(to: 20).getDocuments(completion: {(snapshot, err) in
            if let err = err {
                let alert = UIAlertController(title: "Alert", message: err.localizedDescription, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                var temp:messageCodable
                for documents in snapshot!.documents{
                    let jsonData = try! JSONSerialization.data(withJSONObject: documents.data(), options: JSONSerialization.WritingOptions.prettyPrinted)
                    let decoder = JSONDecoder()
                    do
                    {
                        temp = try decoder.decode(messageCodable.self, from: jsonData)
                        if (temp.sid == self.uid && temp.sDel == "false") || (temp.rid == self.uid && temp.rDel == "false"){
                            let newMsg = message(date: temp.date!, message: temp.message!, rDel: temp.rDel!, rid: temp.rid!, rName: temp.rName!, sDel: temp.sDel!, sid: temp.sid!, sName: temp.sName!, type: temp.type!, messageId: documents.documentID, chatId: temp.chatId!)
                                self.msgs.insert(newMsg,at: 0)
                            self.messageTableView.beginUpdates()
                            self.messageTableView.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
                            self.messageTableView.endUpdates()
                        }
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                    self.refreshControl.endRefreshing()
                }
            }
        })
    }
    
//    func bringAllMessages( completion: @escaping (_ error: String?) -> ()){
//        fetchingMore = true
//
//        var query: Query!
//
//        if self.msgs.count == 0 {
//            query = db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).limit(to: 20)
//        } else {
//            query = db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).start(afterDocument: lastDocumentSnapshot).limit(to: 20)
//            self.bringMore = true
//        }
//
//        query.getDocuments { (snapshot, err) in
//            if let err = err {
//                completion(err.localizedDescription)
//            } else if snapshot!.isEmpty {
//                self.fetchingMore = false
//                completion(nil)
//            } else {
//                var temp:messageCodable
//                for documents in snapshot!.documents{
//                    let jsonData = try! JSONSerialization.data(withJSONObject: documents.data(), options: JSONSerialization.WritingOptions.prettyPrinted)
//                    let decoder = JSONDecoder()
//                    do
//                    {
//                        temp = try decoder.decode(messageCodable.self, from: jsonData)
//                        if (temp.sid == self.uid && temp.sDel == "false") || (temp.rid == self.uid && temp.rDel == "false"){
//                            self.msgs.insert(message(date: temp.date!, message: temp.message!, rDel: temp.rDel!, rid: temp.rid!, rName: temp.rName!, sDel: temp.sDel!, sid: temp.sid!, sName: temp.sName!, type: temp.type!, messageId: documents.documentID, chatId: temp.chatId!), at: 0)
//                            self.messageTableView.beginUpdates()
//                            self.messageTableView.insertRows(at: [IndexPath.init(row: 0, section: 0)], with: .automatic)
//                            self.messageTableView.endUpdates()
//                        }
//                    }
//                    catch{
//                        print(error.localizedDescription)
//                    }
//                }
//                if self.bringMore == false{
//                    self.messageTableView.reloadData()
//                }
//
//                self.fetchingMore = false
//                self.lastDocumentSnapshot = snapshot!.documents.last
//                completion(nil)
//            }
//        }
//    }
}
extension chatViewController{
    func getPastTime(for date : Date) -> String {
        
        var secondsAgo = Int(Date().timeIntervalSince(date))
        if secondsAgo < 0 {
            secondsAgo = secondsAgo * (-1)
        }
        
        let minute = 60
        let hour = 60 * minute
        let day = 24 * hour
        let week = 7 * day
        
        if secondsAgo < minute  {
            if secondsAgo < 2{
                return "just now"
            }else{
                return "\(secondsAgo) secs ago"
            }
        } else if secondsAgo < hour {
            let min = secondsAgo/minute
            if min == 1{
                return "\(min) min ago"
            }else{
                return "\(min) mins ago"
            }
        } else if secondsAgo < day {
            let hr = secondsAgo/hour
            if hr == 1{
                return "\(hr) hr ago"
            } else {
                return "\(hr) hrs ago"
            }
        } else if secondsAgo < week {
            let day = secondsAgo/day
            if day == 1{
                return "\(day) day ago"
            }else{
                return "\(day) days ago"
            }
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM dd, hh:mm a"
            formatter.locale = Locale(identifier: "en_US")
            let strDate: String = formatter.string(from: date)
            return strDate
        }
    }

}

