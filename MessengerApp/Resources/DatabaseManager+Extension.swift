//
//  DatabaseManager+Extension.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 5/12/21.
//
import Foundation

extension DatabaseManager{
    public func createNewConversation(otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
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
                "name": name,
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            let recipient_newConversation: [String: Any] = [
                "id": conversationID ,
                "other_user_email": safeEmail,
                "name": "aaaa",
                "latest_message": [
                    "date": dateString,
                    "message": message,
                    "is_read": false
                ]
            ]
            
            //update to recipient user conversation
            self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) {[weak self] (datasnap) in
                guard let self = self else {return}
                if var conversations = datasnap.value as? [[String: Any]] {
                    //append to conv
                    conversations.append(recipient_newConversation)
                    self.database.child("\(otherUserEmail)/conversations").setValue(recipient_newConversation)
                }else{
                    //craete conv
                    self.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversation])
                }
            }

            //update to current user conversation
            if var conversation = userNode["conversations"] as? [[String: Any]]{
                //conversation exists for current user
                //you should append
                conversation.append(newConversation)
                userNode["conversations"] = conversation
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard let self = self else {return}
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self.finishCreateNewConversation(conversationID: conversationID, name: name, firstMessage: firstMessage, completion: completion)
                }
                
            }else{
                //conversation not exsist, we need created
                userNode["conversations"] = [ newConversation ]
                ref.setValue(userNode) {[weak self] (error, _) in
                    guard let self = self else {return}
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self.finishCreateNewConversation(conversationID: conversationID, name: name, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreateNewConversation(conversationID: String, name: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        
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
            "is_read": false,
            "name": name
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
    
    public func getAllConversations(email: String, completion: @escaping (Result<[Conversation],Error>)->Void){
        database.child("\(email)/conversations").observe(.value) { (datasnap) in
            guard let value = datasnap.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations: [Conversation] = value.compactMap { conversationData in
                guard let conversationID = conversationData["id"] as? String,
                      let name = conversationData["name"] as? String,
                      let otherUserEmail = conversationData["other_user_email"] as? String,
                      let latestMessage = conversationData["latest_message"] as? [String: Any],
                      let message = latestMessage["message"] as? String,
                      let date = latestMessage["date"] as? String,
                      let isRead = latestMessage["is_read"] as? Bool else {
                    return nil
                }
                let latestMessageObject = LatestMessage(message: message, date: date, isRead: isRead)
                return Conversation(conversationID: conversationID, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessageObject)
            }
            completion(.success(conversations))
        }
    }
    
    public func getAllMessages(id: String, completion: @escaping (Result<[Message],Error>)->Void){
        database.child("\(id)/messages").observe(.value) { (datasnap) in
            guard let value = datasnap.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages: [Message] = value.compactMap { messageData in
                guard let messageID = messageData["id"] as? String,
                      let name = messageData["name"] as? String,
                      let content = messageData["content"] as? String,
                      let date = messageData["date"] as? String,
                      let senderEmail = messageData["sender_email"] as? String,
                      //let type = messageData["type"] as? String,
                      //let isRead = messageData["is_read"] as? Bool,
                      let messageDateString = ChatViewController.dateFormatter.date(from: date) else {
                    return nil
                }
                let sender = Sender(senderPhoto: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: messageDateString, kind: .text(content))
            }
            completion(.success(messages))
        }
    }
}
