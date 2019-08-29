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
import SDWebImage

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
    private var bringMore = false
    private var selectedIndex:IndexPath!
    private var initiate = false
    private var initiate1 = false
    
    @IBOutlet weak var messageTableView: UITableView!
    @IBOutlet weak var navItem: UINavigationItem!
    var cellHeight:CGFloat!
    var bottomConstraint: NSLayoutConstraint?
    var alertView: UIAlertController!
    var progressDownload: UIProgressView!
    private let refreshControl = UIRefreshControl()
    let navigationView = UIView(frame: CGRect(x: 0, y: 0, width: 50 , height: 55))
    let image : UIImage = UIImage(named: "userProfile")!
    let imageView = UIImageViewRounded(frame: CGRect(x: -100, y: 0, width: 40, height: 40))
    let nameLabel : UILabel = UILabel(frame: CGRect(x: -50, y: 10, width: 200, height: 25))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.messageTableView.delegate = self
        self.messageTableView.dataSource = self
        self.configureUI()
        self.setUpNavigationBar()
    }
    
    private func setUpNavigationBar(){
        nameLabel.text = recvName
        nameLabel.textColor = UIColor.black
        nameLabel.font = UIFont.boldSystemFont(ofSize: 18)
        navigationView.addSubview(nameLabel)
        
        imageView.borderColor = UIColor(red: 44/255, green: 118/255, blue: 211/255, alpha: 1.0)
        imageView.circular = true
        imageView.borderWidth = 2.0
        imageView.contentMode = .scaleAspectFit
        imageView.image = image
        
        navigationView.addSubview(imageView)
        navItem.titleView = navigationView
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        IQKeyboardManager.shared().isEnableAutoToolbar = true
        IQKeyboardManager.shared().isEnabled = true
        staticLinker.listnerRef.remove()
        staticLinker.listnerRef1.remove()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.nameLabel.text = self.recvName
        self.chatListner()
        self.userInfoListner()
        IQKeyboardManager.shared().isEnableAutoToolbar = false
        IQKeyboardManager.shared().isEnabled = false
    }
    
    private func configureUI(){
        self.messageTableView.separatorStyle = UITableViewCell.SeparatorStyle.none
        self.messageTableView.refreshControl = self.refreshControl
        self.messageTableView.estimatedRowHeight = 100
        self.refreshControl.addTarget(self, action: #selector(loadData), for: .valueChanged)
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
            self.messageField.text = ""
            let date = String(Date().timeIntervalSince1970)
            self.userActivityObj.sendMessage(formattedDate: date, sid: self.uid!, rid: recvId!, sName: uName!, rName: recvName!, _message: m, completion: {(error,msg) in
                if let err = error{
                    let alert = UIAlertController(title: "Alert", message: err, preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
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
        if msgs[indexPath.row].sid == uid{
            if "pic" == msgs[indexPath.row].type {
                let cell = self.messageTableView.cellForRow(at: indexPath) as! messageBubbleIncomingPictureCell
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
            }else{
                let cell = self.messageTableView.cellForRow(at: indexPath) as! messageBubbleIncomingCell
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
            }
        }else{
            if "pic" == msgs[indexPath.row].type {
                let cell = self.messageTableView.cellForRow(at: indexPath) as! messageBubbleIncomingPictureCell
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
            }else{
                let cell = self.messageTableView.cellForRow(at: indexPath) as! messageBubbleOutgoingCell
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
            }
        }
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
        if msgs[indexPath.row].sid == uid{
            if "pic" == msgs[indexPath.row].type {
                let cell = tableView.dequeueReusableCell(withIdentifier: "outgoingPic") as! messageBubbleIncomingPictureCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
                cell.showIncomingMessage(cellWidth: self.view.bounds.width)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "outgoing") as! messageBubbleIncomingCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                let msg = msgs[indexPath.row].message
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
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
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
                cell.showIncomingMessage(cellWidth: self.view.bounds.width)
                return cell
            }else{
                let cell = tableView.dequeueReusableCell(withIdentifier: "incoming") as! messageBubbleOutgoingCell
                if self.selectedIndex == indexPath{
                    cell.stackView.arrangedSubviews.last?.isHidden = false
                    cell.stackView.arrangedSubviews.first?.isHidden = false
                }
                let msg = msgs[indexPath.row].message
                let data = staticLinker.getPastStatus(date: self.msgs[indexPath.row].date)
                cell.date.text = data.1
                cell.status.text = staticLinker.getPastTime(for: data.0)
                cell.message.text = msg
                cell.showOutgoingMessage(text: msg, cellWidth: self.view.bounds.width)
                return cell
            }
        }
    }
}

extension chatViewController{
    
    func showSendProgress(){
        self.alertView = UIAlertController(title: "Sending", message: "0%", preferredStyle: .alert)
        alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: {(_) in
            staticLinker.imageUploadProgress.cancel()
        }))
        self.progressDownload = UIProgressView(progressViewStyle: .default)
        self.progressDownload.setProgress(0.0, animated: true)
        self.progressDownload.frame = CGRect(x: 10, y: 70, width: 250, height: 0)
        alertView.view.addSubview(progressDownload)
        present(alertView, animated: true, completion: nil)
        
        staticLinker.imageUploadProgress.observe(.progress) { snapshot in
            if let error = snapshot.error{
                self.alertView.title = "Error"
                self.alertView.message = error.localizedDescription
                self.dismiss(animated: true, completion: nil)
            }else{
                self.progressDownload.setProgress(Float(snapshot.progress!.fractionCompleted), animated: true)
                self.alertView.message = String(Int(snapshot.progress!.fractionCompleted * 100))
                if snapshot.progress!.isFinished{
                    staticLinker.imageUploadProgress.removeAllObservers()
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        }
    }
    
    func chatListner(){
        staticLinker.listnerRef = db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).limit(to: 5).addSnapshotListener({(snapshot, err) in
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
                if self.msgs.count == 0{self.msg = "No Messages"; self.messageTableView.reloadData()}
                if self.initiate == false{
                    self.messageTableView.reloadData()
                    if let lastDocIndex = snapshot!.documents.last{
                        self.lastDocumentSnapshot = lastDocIndex
                        self.initiate = true
                    }
                }else{
                    let indexPath = IndexPath(item: self.msgs.count - 1, section: 0)
                    self.messageTableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        })
    }
    
    func bringMoreMessages(){
        if let lastDocSnap = self.lastDocumentSnapshot{
            db.collection("messages").whereField("chatId", isEqualTo: self.chatId!).order(by: "date", descending: true).start(afterDocument: lastDocSnap).limit(to: 20).getDocuments(completion: {(snapshot, err) in
                self.refreshControl.endRefreshing()
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
                                if self.selectedIndex != nil{
                                    self.selectedIndex.row += 1
                                }
                                self.messageTableView.endUpdates()
                            }
                        }
                        catch{
                            print(error.localizedDescription)
                        }
                    }
                }
            })
        }else{
            self.refreshControl.endRefreshing()
        }
    }
    
    func userInfoListner(){
        self.userActivityObj.getUser(id: self.recvId, completion: {(error,user) in
            if let err = error{
                print(err)
            }else{
                if self.initiate1 == false{
                    if user!.isActive{
                        self.imageView.borderColor = UIColor(red: 7/255, green: 224/255, blue: 40/255, alpha: 1.0)
                    }else{
                        self.imageView.borderColor = UIColor(red: 71/255, green: 92/255, blue: 102/255, alpha: 1.0)
                    }
                    if user?.image != ""{
                        self.imageView.sd_setImage(with: URL(string: user!.image), completed: nil)
                    }
                    self.initiate1 = true
                }else{
                    if user!.isActive{
                        self.imageView.borderColor = UIColor(red: 7/255, green: 224/255, blue: 40/255, alpha: 1.0)
                    }else{
                        self.imageView.borderColor = UIColor(red: 71/255, green: 92/255, blue: 102/255, alpha: 1.0)
                    }
                }
            }
        })
    }
}

