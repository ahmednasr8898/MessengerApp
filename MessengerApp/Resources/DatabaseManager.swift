//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/6/21.
//
import Foundation
import FirebaseDatabase

///class for read and write data in real time database in firebase
final class DatabaseManager {
    
    static let shared = DatabaseManager()
    let database = Database.database().reference()
    
    public func checkIfUserExist(email: String, completion: @escaping (Bool)-> Void){
        
        let safeEmail = DatabaseManager.getSafeEmail(email: email)
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (datasnap) in
            guard datasnap.value as? [String: Any] != nil else {
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    static func getSafeEmail(email: String)-> String{
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    ///insert new user in real time database when user done register
    public func insertNewUser(user: UserModel, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue(["first_name": user.firstName, "last_name": user.lastName]) {[weak self] (error, _) in
            guard let self = self else {return}
            
            guard error == nil else{
                print("failed to insert user")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) { (datasnap) in
                if var usersCollection = datasnap.value as? [[String: String]] {
                    //insert to users
                    let newElement: [[String: String]] = [["name": user.firstName + " " + user.lastName, "email": user.safeEmail]]
                    usersCollection.append(contentsOf: newElement)
                    self.database.child("users").setValue(usersCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }else{
                    //create users array
                    let newCollection: [[String: String]] = [["name": user.firstName + " " + user.lastName, "email": user.safeEmail]]
                    self.database.child("users").setValue(newCollection) { (error, _) in
                        guard error == nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
            completion(true)
        }
    }
    ///return all user from database
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value) { (datasnap) in
            guard let value = datasnap.value as? [[String: String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public func getData(path: String, completion: @escaping (Result<Any,Error>)->Void){
        database.child(path).observeSingleEvent(of: .value) { (datasnap) in
            guard let value = datasnap.value as? [[String: Any]] else {
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    
    public enum DatabaseError: Error{
        case failedToFetch
    }
    
    public func conversationExists(with targetRecipientEmail: String, completion: @escaping (Result<String, Error>)-> Void){
        let safeRecipientEmail = DatabaseManager.getSafeEmail(email: targetRecipientEmail)
        guard let senderEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeSenderEmail = DatabaseManager.getSafeEmail(email: senderEmail)
        
        database.child("\(safeRecipientEmail)/conversations").observeSingleEvent(of: .value) { datasnap in
            guard let collection = datasnap.value as? [[String: Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            
            if let conversation = collection.first(where: {
                guard let targetSenderEmail = $0["other_user_email"] as? String else {
                    return false
                }
                return safeSenderEmail == targetSenderEmail
                
            }){
                //get id
                guard let id = conversation["id"] as? String else {
                    completion(.failure(DatabaseError.failedToFetch))
                    return
                }
                completion(.success(id))
                return
            }
            completion(.failure(DatabaseError.failedToFetch))
            return
        }
    }
}

