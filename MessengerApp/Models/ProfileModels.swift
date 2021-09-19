//
//  ProfileModels.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 19/09/2021.
//

import Foundation

enum profileViewModelType {
    case info, logout
}
struct ProfileViewModel {
    let viewModelType: profileViewModelType
    let title: String
    let handler: (() -> Void)?
}
