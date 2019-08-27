//
//  userActivity.swift
//  ChatApp
//
//  Created by Kashif Rizwan on 8/20/19.
//  Copyright © 2019 Dima Nikolaev. All rights reserved.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

struct user_activity{
    
    let db = Firestore.firestore()
    let uid = Auth.auth().currentUser?.uid
    
    func isUserActive(isActive: Bool, completion: @escaping (_ error: String?) -> ()){
        self.db.collection("chatUser").document(Auth.auth().currentUser!.uid).setData(["isActive":"true"], completion: {(error) in
            if let err = error{
                completion(err.localizedDescription)
            }else{
                completion(nil)
            }
        })
    }
    
    func sendMessage(formattedDate: String, sid:String, rid:String, sName:String, rName:String, _message:String, completion: @escaping (_ error: String?, _ msg: message?) -> ()){
        var chatId = String()
        if sid > rid{
            chatId = sid + rid
        }else{
            chatId = rid + sid
        }
        var ref:DocumentReference?
        ref = self.db.collection("messages").addDocument(data: ["sid":sid,"rid":rid, "sName":sName, "rName":rName,"message": _message,"type":"txt", "sDel":"false", "rDel":"false","date":formattedDate,"chatId":chatId], completion: {(error) in
            if let err = error{
                completion(err.localizedDescription,nil)
            }else{
                self.addToChat(formattedDate: formattedDate, chatId: chatId, sid: sid, rid: rid, sName: sName, rName: rName, message: _message, type: "txt", completion: {(error) in
                    if let err = error{
                        completion(err,nil)
                    }else{
                        let msg = message(date: formattedDate, message: _message, rDel: "false", rid: rid, rName: rName, sDel: "false", sid: sid, sName: sName, type: "txt", messageId: ref!.documentID, chatId: chatId)
                        completion(nil,msg)
                    }
                })
            }
        })
    }
    
    func sendPicture( sid:String, rid:String, sName:String, rName:String, _message:UIImage, completion: @escaping (_ error: String?, _ msg: message?) -> ()){
        let formattedDate = String(Date().timeIntervalSince1970)
        var chatId = String()
        if sid > rid{
            chatId = sid + rid
        }else{
            chatId = rid + sid
        }
        self.uploadImage(imageId: formattedDate, image: _message, completion: {(error,url) in
            var ref:DocumentReference?
            if let err = error{
                completion(err,nil)
            }else if let Url = url{
                ref = self.db.collection("messages").addDocument(data: ["sid":sid,"rid":rid,"sName":sName, "rName":rName,"sDel":"false", "rDel":"false","message":Url,"type":"img","date":formattedDate,"chatId":chatId], completion: {(error) in
                    if let err = error{
                        completion(err.localizedDescription,nil)
                    }else{
                        if let err = error{
                            completion(err.localizedDescription,nil)
                        }else if let Url = url{
                            self.addToChat(formattedDate: formattedDate, chatId: chatId, sid: sid, rid: rid, sName: sName, rName: rName, message: Url.absoluteString, type: "img", completion: {(error) in
                                if let err = error{
                                    completion(err,nil)
                                }else{
                                    let msg = message(date: formattedDate, message: Url.absoluteString, rDel: "false", rid: rid, rName: rName, sDel: "false", sid: sid, sName: sName, type: "img", messageId: ref!.documentID, chatId: chatId)
                                    completion(nil, msg)
                                }
                            })
                        }
                    }
                })
            }
        })
    }
    
    func addToChat(formattedDate:String,chatId:String, sid:String, rid:String, sName:String, rName:String, message:String, type:String, completion: @escaping (_ error:String?) ->()){
        self.db.collection("chat").document(chatId).setData(["sid":sid,"rid":rid,"sName":sName, "rName":rName,"sDel":"false", "rDel":"false","message":message,"type":type,"date":formattedDate,"chatId":chatId], completion: {(error) in
            if let err = error{
                completion(err.localizedDescription)
            }else{
                completion(nil)
            }
        })
    }
    
    func uploadImage(imageId:String, image:UIImage?, completion: @escaping (_ error: String?,_ url:URL?) -> ()){
        let data = image!.jpegData(compressionQuality: 1.0)
        let imageUpload = Storage.storage().reference().child("Images/\(imageId))/profilePic.jpg")
        _ = imageUpload.putData(data!, metadata: nil) { (metadata, error) in
            if let err = error {
                completion(err.localizedDescription,nil)
            }else{
                imageUpload.downloadURL(completion: { (url, error) in
                    if let err = error {
                        completion(err.localizedDescription,nil)
                    }else{
                        completion(nil,url)
                    }
                })
            }
        }
    }
    
    func uploadProfileImage( image:UIImage?, completion: @escaping (_ error: String?,_ url:URL?) -> ()){
        let data = image!.jpegData(compressionQuality: 1.0)
        let imageUpload = Storage.storage().reference().child("Images/\(String(describing: uid!))/profilePic.jpg")
        _ = imageUpload.putData(data!, metadata: nil) { (metadata, error) in
            if let err = error {
                completion(err.localizedDescription,nil)
            }else{
                imageUpload.downloadURL(completion: { (url, error) in
                    if let err = error {
                        completion(err.localizedDescription,nil)
                    }else{
                        completion(nil,url)
                    }
                })
            }
        }
    }
    
    func getAllChats(completion: @escaping (_ error: String?,_ messages:[message]?) -> ()){
        self.db.collection("chat").addSnapshotListener({(snapshot, error) in
            if let err = error{
                completion(err.localizedDescription,nil)
            }else{
                var temp:messageCodable
                var DataArray = [message]()
                for documents in snapshot!.documents{
                    let jsonData = try! JSONSerialization.data(withJSONObject: documents.data(), options: JSONSerialization.WritingOptions.prettyPrinted)
                    let decoder = JSONDecoder()
                    do
                    {
                        temp = try decoder.decode(messageCodable.self, from: jsonData)
                        if (temp.sid == self.uid && temp.sDel == "false") || (temp.rid == self.uid && temp.rDel == "false"){
                            DataArray.append(message(date: temp.date!, message: temp.message!, rDel: temp.rDel!, rid: temp.rid!, rName: temp.rName!, sDel: temp.sDel!, sid: temp.sid!, sName: temp.sName!, type: temp.type!, messageId: documents.documentID, chatId: temp.chatId!))
                        }
                    }
                    catch{
                        print(error.localizedDescription)
                    }
                }
                if DataArray.count == 0{
                    completion(nil,nil)
                }else{
                    completion(nil,DataArray)
                }
            }
        })
    }
    
}
