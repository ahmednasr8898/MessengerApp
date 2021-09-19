//
//  UserModels.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 19/09/2021.
//

import Foundation

struct UserModel {
    let firstName: String
    let lastName: String
    let email: String
    var safeEmail: String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    var profilePicFileName: String {
        return "\(safeEmail)_profile_picture.png"
    }
}
