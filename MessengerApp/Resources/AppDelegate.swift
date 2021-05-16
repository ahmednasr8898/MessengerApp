// Swift
//
// AppDelegate.swift
import UIKit
import FBSDKCoreKit
import Firebase
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GIDSignInDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance()?.delegate = self
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
        return GIDSignIn.sharedInstance().handle(url)
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        guard error == nil else {
            if let error = error {
                print("Failed to sign in with Google: \(error)")
            }
            return
        }
        guard let user = user else {
            return
        }
        guard let email = user.profile.email, let firstName = user.profile.givenName, let lastName = user.profile.familyName else {
            return
        }
        
        DatabaseManager.shared.checkIfUserExist(email: email) { (isExist) in
            if !isExist{
                let myUser = UserModel(firstName: firstName, lastName: lastName, email: email)
                DatabaseManager.shared.insertNewUser(user: myUser) { (success) in
                    //if success upload profile picture
                    if success{
                        UserDefaults.standard.set(email, forKey: "email")
                        UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                        if user.profile.hasImage {
                            guard let url = user.profile.imageURL(withDimension: 200) else {
                                return
                            }
                            
                            print("Downloading data from google image")
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _,_ in
                                guard let data = data else {
                                    print("Failed to get data from google")
                                    return
                                }
                                
                                print("got data from google, uploading...")
                                let fileName = myUser.profilePicFileName
                                StorageManager.shared.uploadProfilePicture(data: data, fileName: fileName) { (result) in
                                    switch result{
                                    case .failure(let error):
                                        print("storge manager error\(error)")
                                    case .success(let profilePicUrl):
                                        UserDefaults.standard.set(profilePicUrl, forKey: "profile_pic_url")
                                        print("profile pic url \(profilePicUrl)")
                                    }
                                }
                            }).resume()
                        }
                    }
                }
            }
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
        
        FirebaseAuth.Auth.auth().signIn(with: credential) { (result, error) in
            guard result != nil, error == nil else {
                print("failed to log in with google credential")
                return
            }
            // login success
            print("Successfully signed in with Google cred.")
            NotificationCenter.default.post(name: NSNotification.Name("didLogInNotification"), object: nil)
        }
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
        print("Google user was disconnected")
    }
}


