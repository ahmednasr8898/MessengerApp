//
//  DatabaseManager.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/6/21.
//
import Foundation
import FirebaseDatabase

final class DatabaseManager {
    
    static let shared = DatabaseManager()
    let database = Database.database().reference()
    
    public func checkIfUserExist(email: String, completion: @escaping (Bool)-> Void){
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        
        database.child(safeEmail).observeSingleEvent(of: .value) { (datasnap) in
            guard datasnap.value as? String != nil else {
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
    
    public func insertNewUser(user: UserModel, completion: @escaping (Bool)->Void){
        database.child(user.safeEmail).setValue(["first_name": user.firstName, "last_name": user.lastName]) { (error, _) in
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
    
    public func getAllUsers(completion: @escaping (Result<[[String: String]], Error>)-> Void){
        database.child("users").observeSingleEvent(of: .value) { (datasnap) in
            guard let value = datasnap.value as? [[String: String]] else{
                completion(.failure(DatabaseError.failedGetUsers))
                return
            }
            completion(.success(value))
        }
        
    }
    
    public enum DatabaseError: Error{
        case failedGetUsers
    }
}

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
