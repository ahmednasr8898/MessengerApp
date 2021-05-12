//
//  DatabaseManager+Extension.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 5/12/21.
//
import Foundation

extension DatabaseManager{
    public func createNewConversation(otherUserEmail: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        guard let currentUserEmail = UserDefaults.standard.object(forKey: "email") as? String else { return }
        let safeEmail = DatabaseManager.getSafeEmail(email: currentUserEmail)
        let ref = database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) { (datasnap) in
            guard var userNode = datasnap.value as? [String: Any] else {
                completion(false)
                print("user not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch firstMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
            case .video(_):
                break
            case .location(_):
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .linkPreview(_):
                break
            case .custom(_):
                break
            }
            
            let conversationID = "conversation_\(firstMessage.messageId)"
            let newConversation: [String: Any] = [
                "id": conversationID ,
                "other_user_email": otherUserEmail,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            if var conversation = userNode["conversations"] as? [[String: Any]]{
                //conversation exists for current user
                //you should append
                conversation.append(newConversation)
                userNode["conversations"] = conversation
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreateNewConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }else{
                //conversation not exsist, we need created
                userNode["conversations"] = [ newConversation ]
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreateNewConversation(conversationID: conversationID, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreateNewConversation(conversationID: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message = ""
        
        switch firstMessage.kind{
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {
            completion(false)
            return
        }
        
        let currentUserEmail = DatabaseManager.getSafeEmail(email: email)
        
        let collectiosMessage: [String: Any] = [
            "id": firstMessage.messageId,
            "type": firstMessage.kind.messageKindString,
            "content": message,
            "date": dateString,
            "sender_email": currentUserEmail,
            "is_read": false
        ]
        
        let value: [String: Any] = [
            "messages": [collectiosMessage]
        ]
        
        database.child("\(conversationID)").setValue(value) { (error, _) in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
}
