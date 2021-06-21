//
//  StorageManager.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/8/21.
//

import Foundation
import FirebaseStorage

final class StorageManager{
    
    static let shared = StorageManager()
    private let storage = FirebaseStorage.Storage.storage().reference()
    
    public typealias uploadPictureCompletion = (Result<String, Error>) -> Void
    
    public func uploadProfilePicture(data: Data, fileName: String, completion: @escaping uploadPictureCompletion){
        storage.child("images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else{
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to get url for profile picture")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                let urlString = url.absoluteString
                print("url for profile picture \(urlString)")
                completion(.success(urlString))
            }
        })
    }
    
    public func uploadPhotoMessage(data: Data, fileName: String, completion: @escaping uploadPictureCompletion){
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: {[weak self] metadata, error in
            guard let self = self else {return}
            guard error == nil else{
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            
            self.storage.child("message_images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("failed to get url for photo message")
                    completion(.failure(StorageErrors.failedToGetUrl))
                    return
                }
                let urlString = url.absoluteString
                print("url for photo message \(urlString)")
                completion(.success(urlString))
            }
        })
    }
    
    public func downloadUrl(path: String, completion: @escaping (Result<URL,Error>)-> Void){
        let ref = storage.child(path)
        ref.downloadURL { (url, error) in
            guard let url = url, error == nil else {
                completion(.failure(StorageErrors.failedToGetUrl))
                return
            }
            completion(.success(url))
        }
    }
    
    public enum StorageErrors: Error{
        case failedToUpload
        case failedToGetUrl
    }
}
