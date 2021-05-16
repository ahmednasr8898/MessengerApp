//
//  LoginViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/6/21.
//
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn
import JGProgressHUD

class LoginViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let logoImageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(named: "logo")
        image.contentMode = .scaleAspectFit
        return image
    }()
    
    private let emailTextField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "Email Address..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .secondarySystemBackground
        return email
    }()
    
    private let passwordTextField: UITextField = {
        let password = UITextField()
        password.autocapitalizationType = .none
        password.autocorrectionType = .no
        password.returnKeyType = .done
        password.layer.cornerRadius = 12
        password.layer.borderWidth = 1
        password.layer.borderColor = UIColor.lightGray.cgColor
        password.placeholder = "Password..."
        password.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        password.leftViewMode = .always
        password.backgroundColor = .secondarySystemBackground
        //password.isSecureTextEntry = true
        return password
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["public_profile", "email"]
        return button
        
    }()
    
    private let googleLogInButton = GIDSignInButton()
    
    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDesign()
        notificationCenterForLoginGoogle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setUpCoordinates()
    }
    
    private func setUpDesign(){
        //setup navigation item
        view.backgroundColor = .systemBackground
        title = "Log In"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: .done, target: self, action: #selector(didTapRegister))
        //delegates
        emailTextField.delegate = self
        passwordTextField.delegate = self
        facebookLoginButton.delegate = self
        GIDSignIn.sharedInstance()?.presentingViewController = self
        //Add subViews
        view.addSubview(scrollView)
        scrollView.addSubview(logoImageView)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLogInButton)
    }
    
    private func setUpCoordinates(){
        scrollView.frame = view.bounds
        let size = scrollView.width/3.5
        logoImageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailTextField.frame = CGRect(x: 30, y: logoImageView.bottom+15, width: scrollView.width-60, height: 52)
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom+15, width: scrollView.width-60, height: 52)
        loginButton.frame = CGRect(x: 30, y: passwordTextField.bottom+15, width: scrollView.width-60, height: 52)
        facebookLoginButton.frame = CGRect(x: 30, y: loginButton.bottom+10, width: scrollView.width-60, height: 52)
        googleLogInButton.frame = CGRect(x: 30, y: facebookLoginButton.bottom+10, width: scrollView.width-60, height: 52)
    }
    
    @objc func didTapRegister(){
        let registerVC = RegisterViewController()
        navigationController?.pushViewController(registerVC, animated: true)
    }
    
    @objc private func didTapLogin(){
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        vaildFields()
    }
    
    private func notificationCenterForLoginGoogle(){
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name("didLogInNotification"), object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        })
    }
    
    deinit {
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func vaildFields(){
        guard let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty, password.count >= 6 else {
            self.alertError(title: "problem happend!", message: "please, enter all information to login...")
            return
        }
        spinner.show(in: view)
        // login with firebase
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let strongSelf = self else{return}
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            guard error == nil else{
                print("error when login")
                return
            }
            let safeEmail = DatabaseManager.getSafeEmail(email: email)
            DatabaseManager.shared.getData(path: safeEmail) { (result) in
                switch result{
                case .failure(let error):
                    print("failed to get data \(error)")
                case .success(let value):
                    guard let userData = value as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                }
            }
            UserDefaults.standard.setValue(email, forKey: "email")
            print("Login is success")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        }
    }
}

extension LoginViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        }else if textField == passwordTextField{
            didTapLogin()
        }
        return true
    }
}

extension LoginViewController: LoginButtonDelegate{
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("error when get token, login by facebook")
            return
        }
        
        let facebookRequest = FBSDKLoginKit.GraphRequest(graphPath: "me", parameters: ["fields": "email, first_name, last_name, picture.type(large)"], tokenString: token, version: nil, httpMethod: .get)
        
        facebookRequest.start { (_, result, error) in
            guard let result = result as? [String: Any], error == nil else{
                print("Failed to make facebook graph request")
                return
            }
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String else {
                print("Faield to get email and name from fb result")
                return
            }
            
            DatabaseManager.shared.checkIfUserExist(email: email) { (isExist) in
                if !isExist{
                    let user = UserModel(firstName: firstName, lastName: lastName, email: email)
                    DatabaseManager.shared.insertNewUser(user: user) { (success) in
                        //if success upload profile picture
                        if success{
                            UserDefaults.standard.set(email, forKey: "email")
                            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            print("Downloading data from facebook image")
                            URLSession.shared.dataTask(with: url, completionHandler: { data, _,_ in
                                guard let data = data else {
                                    print("Failed to get data from facebook")
                                    return
                                }
                                print("got data from FB, uploading...")
                                let fileName = user.profilePicFileName
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
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] (result, error) in
                guard let strongSelf = self else {
                    return
                }
                guard result != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may be needed - \(error)")
                    }
                    return
                }
                print("Successfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        print("log out")
    }
}
