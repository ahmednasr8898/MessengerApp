//
//  NewConversationCell.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 6/21/21.
//

import UIKit
import SDWebImage

class NewConversationCell: UITableViewCell {
    
    static let identfire = "NewConversationCell"
    
    private let userImageView: UIImageView = {
        let image = UIImageView()
        image.contentMode = .scaleAspectFit
        image.layer.cornerRadius = 35
        image.layer.masksToBounds = true
        return image
    }()
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 21, weight: .semibold)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(userImageView)
        contentView.addSubview(userNameLabel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        userImageView.frame = CGRect(x: 10, y: 10, width: 70, height: 70)
        userNameLabel.frame = CGRect(x: userImageView.right + 10, y: 20, width: contentView.width - 20 - userImageView.width, height: 50)
    }
    
    public func configure(model: SearchResult){
        userNameLabel.text = model.name
        
        let path = "images/\(model.email)_profile_picture.png"
        StorageManager.shared.downloadUrl(path: path) {[weak self] (result) in
            guard let self = self else {return}
            
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
