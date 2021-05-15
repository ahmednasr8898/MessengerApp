//
//  ConversationTableViewCell.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 5/15/21.
//
import UIKit
import SDWebImage

class ConversationTableViewCell: UITableViewCell {
    
    static let identfire = "ConversationTableViewCell"
    
    private let userImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 50
        image.layer.masksToBounds = true
        return image
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    private let latestMessageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .regular)
        label.numberOfLines = 0
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
        contentView.addSubview(latestMessageLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 100, height: 100)
        
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 10, width: contentView.width - 20 - userImageView.width, height: (contentView.height-20)/2)
        
        latestMessageLabel.frame = CGRect(x: userImageView.right + 10, y: userNameLabel.bottom + 10, width: contentView.width - 20 - userImageView.width,height: (contentView.height-20)/2)
    }
    
    public func configure(model: Conversation){
        self.userNameLabel.text = model.name
        self.latestMessageLabel.text = model.latestMessage.message
        
        let path = "images/\(model.otherUserEmail)_profile_picture.png"
        StorageManager.shared.downloadUrl(path: path) { (result) in
            switch result{
            case .failure(let error):
                print("failed to download url for profile pic in conversation \(error)")
            case .success(let url):
                DispatchQueue.main.async {
                    self.userImageView.sd_setImage(with: url, completed: nil)
                }
            }
        }
        
    }
}
