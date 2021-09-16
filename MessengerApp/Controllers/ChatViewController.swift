//
//  ChatViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/8/21.
//
import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import CoreLocation

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

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoUrl: URL?
    
    public static let dateFormatter: DateFormatter = {
        let date = DateFormatter()
        date.dateStyle = .medium
        date.timeStyle = .long
        date.locale = .current
        return date
    }()
    
    private var conversationID: String?
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
        messagesCollectionView.messageCellDelegate = self
        setupInputButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    private func setupInputButton(){
        let attachButton = InputBarButtonItem()
        attachButton.setSize(CGSize(width: 35, height: 35), animated: false)
        attachButton.setImage(UIImage(systemName: "paperclip"), for: .normal)
        attachButton.onTouchUpInside {[weak self] (_) in
            guard let self = self else {return}
            self.presentInputActionsheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: true)
        messageInputBar.setStackViewItems([attachButton], forStack: .left, animated: false)
    }
    
    private func presentInputActionsheet(){
        let sheet = UIAlertController(title: "Attach Media", message: "what would you like to attach", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: {[weak self] (_) in
            guard let self = self else {return}
            self.presentPhotoActionsheet()
        }))
        sheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { (_) in
        }))
        sheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { (_) in
            
        }))
        sheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] (_) in
            self?.presentLocationPicker()
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(sheet, animated: true, completion: nil)
    }
    
    private func presentLocationPicker(){
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Picker Location"
        vc.isPickable = true
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {[weak self] selectCoordinates in
            guard let self = self else { return }
            
            guard let messageID = self.createMessageID(),
                  let conversationID = self.conversationID,
                  let name = self.title,
                  let selfSender = self.selfSender else {
                return
            }
            
            let longitude: Double = selectCoordinates.longitude
            let latitude: Double = selectCoordinates.latitude
            
            print("longitude \(longitude) : latitude \(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .location(location))
            DatabaseManager.shared.sendMessages(conversationID: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                if success{
                    print("success to send location message")
                }else{
                    print("failed to send location message")
                }
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoActionsheet(){
        let sheet = UIAlertController(title: "Attach Photo", message: "where would you like to attach photo from", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: {[weak self] (_) in
            guard let self = self else {return}
            let picker = UIImagePickerController()
            picker.allowsEditing = true
            picker.sourceType = .camera
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }))
        sheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: {[weak self] (_) in
            guard let self = self else {return}
            let picker = UIImagePickerController()
            picker.allowsEditing = true
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }))
        sheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        present(sheet, animated: true, completion: nil)
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

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage,
              let imageData = image.pngData(),
              let messageID = createMessageID(),
              let conversationID = conversationID,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        let filePath = "photo_message_" + messageID.replacingOccurrences(of: " ", with: "-") + ".png"
        
        //upload image
        StorageManager.shared.uploadPhotoMessage(data: imageData, fileName: filePath) {[weak self] (result) in
            guard let self = self else {return}
            switch result{
            case .failure(let error):
                print("message photo failed to upload \(error)")
            case .success(let urlString):
                //send photo message
                print("uploaded message photo \(urlString)")
                guard let url = URL(string: urlString),
                      let placeholder = UIImage(systemName: "plus")  else {
                    return
                }
                let media = Media(url: url, image: nil, placeholderImage: placeholder, size: .zero)
                let message = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .photo(media))
                DatabaseManager.shared.sendMessages(conversationID: conversationID, otherUserEmail: self.otherUserEmail, name: name, newMessage: message) { (success) in
                    if success{
                        print("success to send photo message")
                    }else{
                        print("failed to send photo message")
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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {return}
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url  else {return}
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    
    // change color for message
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            //sender message
            return .link
        }
        return .secondarySystemBackground
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId{
            //show my image
            if let currentUserImageUrl = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageUrl, completed: nil)
            }
            else{
                //get url
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.getSafeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadUrl(path: path) { [weak self] result in
                    guard let self = self else {return}
                    switch result{
                    case .success(let url):
                        self.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                }
            }
        }
        else{
            //show other user image
            if let otherUserPhotoUrl = self.otherUserPhotoUrl{
                avatarView.sd_setImage(with: otherUserPhotoUrl, completed: nil)
            }
            else{
                //get url
                let email = self.otherUserEmail
                
                let safeEmail = DatabaseManager.getSafeEmail(email: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                StorageManager.shared.downloadUrl(path: path) { [weak self] result in
                    guard let self = self else {return}
                    switch result{
                    case .success(let url):
                        self.otherUserPhotoUrl = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                }
            }
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty, let selfSender = self.selfSender, let messageID = createMessageID() else {
            return
        }
        
        print("\(text)")
        
        let messege = Message(sender: selfSender, messageId: messageID, sentDate: Date(), kind: .text(text))
        
        if isNewConversation{
            //create new conversation in database
            DatabaseManager.shared.createNewConversation(otherUserEmail: otherUserEmail, name: title ?? " ", firstMessage: messege) { (success) in
                if success{
                    print("message send")
                    self.isNewConversation = false
                    let conversationid = "conversation_\(messege.messageId)"
                    self.conversationID = conversationid
                    self.fetchMessages(id: conversationid, shouldScrollToBottom: true)
                    self.messageInputBar.inputTextView.text = nil
                }else{
                    print("failed to+ send message")
                }
            }
        }else{
            guard let conversationId = conversationID, let name = self.title else { return }
            //append messege in conversation in database
            DatabaseManager.shared.sendMessages(conversationID: conversationId, otherUserEmail: otherUserEmail, name: name, newMessage: messege) {[weak self] (success) in
                if success{
                    print("send message")
                    self?.messageInputBar.inputTextView.text = nil
                }else{
                    print("failed to send message")
                }
            }
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

extension ChatViewController: MessageCellDelegate{
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {return}
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locatioData):
            let coordinates = locatioData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            vc.isPickable = false
            vc.title = "Location"
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {return}
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {return}
            let vc = PhotoViewerViewController(url: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
}
