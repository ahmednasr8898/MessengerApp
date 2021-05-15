//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/8/21.
//
import UIKit
import MessageKit
import InputBarAccessoryView

struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

struct Sender: SenderType {
    public var senderPhoto: String
    public var senderId: String
    public var displayName: String
}

extension MessageKind{
    var messageKindString: String{
        switch self{
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter: DateFormatter = {
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .long
        date.locale = .current
        return date
    }()
    
    private let conversationID: String?
    public let otherUserEmail: String
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {
            return nil
        }
        let safeEmail = DatabaseManager.getSafeEmail(email: email)
        return Sender(senderPhoto: "", senderId: safeEmail , displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        self.conversationID = id
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        if let conversationID = conversationID {
            fetchMessages(id: conversationID, shouldScrollToBottom: true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func fetchMessages(id: String, shouldScrollToBottom: Bool){
        DatabaseManager.shared.getAllMessages(id: id) { [weak self](result) in
            guard let self = self else {return}
            switch result{
            case .failure(let error):
                print("failed to get all messages \(error)")
            case .success(let messages):
                guard !messages.isEmpty else {
                    print("failed to get all messages (empty)")
                    return
                }
                print("success to get all messages")
                self.messages = messages
                DispatchQueue.main.async {
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom{
                        self.messagesCollectionView.scrollToLastItem()
                    }
                }
            }
        }
    }
}

extension ChatViewController: MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate {
    func currentSender() -> SenderType {
        return selfSender ?? Sender(senderPhoto: "", senderId: "", displayName: "")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageID = createMessageID() else {
            return
        }
        
        print("\(text)")
        
        if isNewConversation{
            //create new conversation in database
            let messege = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
            DatabaseManager.shared.createNewConversation(otherUserEmail: otherUserEmail, name: title ?? " ", firstMessage: messege) { (success) in
                if success{
                    print("message send")
                }else{
                    print("failed to send message")
                }
            }
        }else{
            //append messege in conversation in database
            
        }
    }
    
    private func createMessageID()-> String? {
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{ return nil }
        let safeCurrentEmail = DatabaseManager.getSafeEmail(email: currentUserEmail)
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newID = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        return newID
    }
}
