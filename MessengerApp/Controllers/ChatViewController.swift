//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/8/21.
//
import UIKit
import MessageKit

class ChatViewController: MessagesViewController {
    
    struct message: MessageType {
        var sender: SenderType
        var messageId: String
        var sentDate: Date
        var kind: MessageKind
    }
    
    struct sender: SenderType {
        var senderPhoto: String
        var senderId: String
        var displayName: String
    }
    
    private var messages = [message]()
    private let selfSender = sender(senderPhoto: "", senderId: "1", displayName: "ans")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messages.append(message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello")))
        messages.append(message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello hello hello hello")))
        messages.append(message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello hello helloHello hello helloHello hello hello")))
        
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
    }
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
