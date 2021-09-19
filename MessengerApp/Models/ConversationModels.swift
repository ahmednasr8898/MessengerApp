//
//  ConversationModels.swift
//  MessengerApp
//
//  Created by Ahmed Nasr on 19/09/2021.
//

import Foundation

struct Conversation {
    let conversationID: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let message: String
    let date: String
    let isRead: Bool
}
