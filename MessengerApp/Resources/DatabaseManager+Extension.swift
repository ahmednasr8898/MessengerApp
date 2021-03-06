//
//  DatabaseManager+Extension.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 5/12/21.
//
import Foundation
import MessageKit
import CoreLocation

extension DatabaseManager{
    ///create new conversation and  added to database real time
    public func createNewConversation(otherUserEmail: String, name: String, firstMessage: Message, completion: @escaping (Bool)-> Void){
        guard let currentUserEmail = UserDefaults.standard.object(forKey: "email") as? String,
              let currentName = UserDefaults.standard.object(forKey: "name") as? String else { return }
        let safeEmail = DatabaseManager.getSafeEmail(email: currentUserEmail)
        let ref = database.child("\(safeEmail)")
        
        ref.observeSingleEvent(of: .value) {[weak self] (datasnap) in
            guard let self = self else {return}
            
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
                "name": currentName,
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
                    self.database.child("\(otherUserEmail)/conversations").setValue(conversations)
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
                      let type = messageData["type"] as? String,
                      //let isRead = messageData["is_read"] as? Bool,
                      let messageDateString = ChatViewController.dateFormatter.date(from: date) else {
                    return nil
                }
                var kind: MessageKind?
                
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                          let placeholder = UIImage(systemName: "plus") else {
                        return nil
                    }
                    let media = Media(url: imageUrl, image: nil, placeholderImage: placeholder, size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                }
                else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                    let latitude = Double(locationComponents[1]) else {
                        return nil
                    }
                    
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                }
                else{
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {return nil}
                
                let sender = Sender(senderPhoto: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender,
                               messageId: messageID,
                               sentDate: messageDateString,
                               kind: finalKind)
            }
            completion(.success(messages))
        }
    }
    
    public func sendMessages(conversationID: String, otherUserEmail: String ,name: String, newMessage: Message, completion: @escaping (Bool)->Void){
        // add new message to messages
        // update sender latest message
        // update recipient latest message
        
        guard let myEmail = UserDefaults.standard.object(forKey: "email") as? String else {
            completion(false)
            return
        }
        let currentEmail = DatabaseManager.getSafeEmail(email: myEmail)
        
        database.child("\(conversationID)/messages").observeSingleEvent(of: .value) {[weak self] (datasnap) in
            guard let self = self else {return}
            
            guard var currentMessages = datasnap.value as? [[String: Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message = ""
            
            switch newMessage.kind{
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString{
                    message = targetUrlString
                }
                break
            case .video(_):
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
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
            
            let newMessageEntry: [String: Any] = [
                "id": newMessage.messageId,
                "type": newMessage.kind.messageKindString,
                "content": message,
                "date": dateString,
                "sender_email": currentUserEmail,
                "is_read": false,
                "name": name
            ]
            
            currentMessages.append(newMessageEntry)
            
            self.database.child("\(conversationID)/messages").setValue(currentMessages) { (error, _) in
                guard error == nil else {
                    completion(false)
                    return
                }
                
                self.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { (datasnap) in
                    var databaseEntryConversation = [[String: Any]]()
                    let updateValue: [String: Any] = [
                        "date": dateString,
                        "is_read": false,
                        "message": message
                    ]
                    
                    guard let currentName = (UserDefaults.standard.value(forKey: "name") as? String) else {
                        return
                    }
                    
                    if var currentUserConversations = datasnap.value as? [[String: Any]] {
                        //need to create conversation entry
                     
                        var targetConversation: [String: Any]?
                        var postion = 0
                        
                        for conversationDictionary in currentUserConversations{
                            if let currentID = conversationDictionary["id"] as? String, currentID == conversationID{
                                targetConversation = conversationDictionary
                                break
                            }
                            postion += 1
                        }
                        
                        if var targetConversation = targetConversation {
                            targetConversation["latest_message"] = updateValue
                            currentUserConversations[postion] = targetConversation
                            databaseEntryConversation = currentUserConversations
                        }
                        else{
                            
                            let newConversation: [String: Any] = [
                                "id": conversationID ,
                                "other_user_email": DatabaseManager.getSafeEmail(email: otherUserEmail),
                                "name": name ,
                                "latest_message": updateValue
                            ]
                            currentUserConversations.append(newConversation)
                            databaseEntryConversation = currentUserConversations
                        }
                    }
                    else{
                        let newConversation: [String: Any] = [
                            "id": conversationID ,
                            "other_user_email": DatabaseManager.getSafeEmail(email: otherUserEmail),
                            "name": name ,
                            "latest_message": updateValue
                        ]
                        databaseEntryConversation = [
                                newConversation
                        ]
                    }
                    self.database.child("\(currentEmail)/conversations").setValue(databaseEntryConversation) { (error, _) in
                        guard error == nil else {
                            completion(false)
                            return
                        }
                        // update latest message for recipient
                        self.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { (datasnap) in
                            
                            let updateValue: [String: Any] = [
                                "date": dateString,
                                "is_read": false,
                                "message": message
                            ]

                            var databaseEntryConversation = [[String: Any]]()
                            
                            if var otherUserConversations = datasnap.value as? [[String: Any]]{
                                var targetConversation: [String: Any]?
                                var postion = 0
                                
                                for conversationDictionary in otherUserConversations{
                                    if let currentID = conversationDictionary["id"] as? String, currentID == conversationID{
                                        targetConversation = conversationDictionary
                                        break
                                    }
                                    postion += 1
                                }
                                
                                if var targetConversation = targetConversation{
                                    targetConversation["latest_message"] = updateValue
                                    otherUserConversations[postion] = targetConversation
                                    databaseEntryConversation = otherUserConversations
                                }
                                else{
                                    // failed to find in current collection
                                    let newConversation: [String: Any] = [
                                        "id": conversationID ,
                                        "other_user_email": DatabaseManager.getSafeEmail(email: currentEmail),
                                        "name": currentName ,
                                        "latest_message": updateValue
                                    ]
                                    otherUserConversations.append(newConversation)
                                    databaseEntryConversation = otherUserConversations
                                }
                            }
                            else{
                                //current collection does not exsist
                                let newConversation: [String: Any] = [
                                    "id": conversationID ,
                                    "other_user_email": DatabaseManager.getSafeEmail(email: currentEmail),
                                    "name": currentName,
                                    "latest_message": updateValue
                                ]
                                databaseEntryConversation = [
                                        newConversation
                                ]
                            }
                            
                            self.database.child("\(otherUserEmail)/conversations").setValue(databaseEntryConversation) { (error, _) in
                                guard error == nil else {
                                    completion(false)
                                    return
                                }
                                completion(true)
                            }
                        }
                    }
                }
            }
        }
    }
    
    public func deleteConversation(conversationID: String, complation: @escaping (Bool)-> Void){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {return}
        let safeEmail = DatabaseManager.getSafeEmail(email: email)
        
        print("deleting conversation by ID: ", conversationID)
        
        //get all conversations for current user
        //delete conversation with id
        //reset conversations for the user
        
        let ref = database.child("\(safeEmail)/conversations")
        ref.observeSingleEvent(of: .value) { (datasnap) in
            if var conversations = datasnap.value as? [[String: Any]]{
                var postionOfConversation = 0
                for conversation in conversations {
                    if let id = conversation["id"] as? String, id == conversationID{
                    
                        print("found vonversation to delete")
                        break
                    }
                    postionOfConversation += 1
                }
                conversations.remove(at: postionOfConversation)
                ref.setValue(conversations) { (error, _) in
                    guard error == nil else {
                        complation(false)
                        print("failed to delete conversation")
                        return
                    }
                    print("deleted conversation")
                    complation(true)
                }
            }
        }
    }
}
