//
//  RegisterViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/6/21.
//
import UIKit
import FirebaseAuth
import JGProgressHUD

final class RegisterViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let profileImageView: UIImageView = {
        let image = UIImageView()
        image.image = UIImage(systemName: "person.circle")
        image.tintColor = .gray
        image.contentMode = .scaleAspectFit
        image.layer.masksToBounds = true
        image.layer.borderWidth = 2
        image.layer.borderColor = UIColor.lightGray.cgColor
        return image
    }()
    
    private let firstNameTextField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "First Name..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .secondarySystemBackground
        return email
    }()
    
    private let lastNameTextField: UITextField = {
        let email = UITextField()
        email.autocapitalizationType = .none
        email.autocorrectionType = .no
        email.returnKeyType = .continue
        email.layer.cornerRadius = 12
        email.layer.borderWidth = 1
        email.layer.borderColor = UIColor.lightGray.cgColor
        email.placeholder = "Last Name..."
        email.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        email.leftViewMode = .always
        email.backgroundColor = .secondarySystemBackground
        return email
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
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.addTarget(self, action: #selector(didTapRegister), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDesign()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setUpCoordinates()
    }
    
    private func setUpDesign(){
        //setup navigation item
        view.backgroundColor = .systemBackground
        title = "Register"
        //setup textfields
        firstNameTextField.delegate = self
        lastNameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        //Add action for profile image
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapProfileImage))
        profileImageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        profileImageView.addGestureRecognizer(tapGesture)
        //Add subViews
        view.addSubview(scrollView)
        scrollView.addSubview(profileImageView)
        scrollView.addSubview(firstNameTextField)
        scrollView.addSubview(lastNameTextField)
        scrollView.addSubview(emailTextField)
        scrollView.addSubview(passwordTextField)
        scrollView.addSubview(registerButton)
    }
    
    private func setUpCoordinates(){
        scrollView.frame = view.bounds
        let size = scrollView.width/3.5
        profileImageView.frame = CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        profileImageView.layer.cornerRadius = profileImageView.width / 2.0
        firstNameTextField.frame = CGRect(x: 30, y: profileImageView.bottom+15, width: scrollView.width-60, height: 52)
        lastNameTextField.frame = CGRect(x: 30, y: firstNameTextField.bottom+15, width: scrollView.width-60, height: 52)
        emailTextField.frame = CGRect(x: 30, y: lastNameTextField.bottom+15, width: scrollView.width-60, height: 52)
        passwordTextField.frame = CGRect(x: 30, y: emailTextField.bottom+15, width: scrollView.width-60, height: 52)
        registerButton.frame = CGRect(x: 30, y: passwordTextField.bottom+15, width: scrollView.width-60, height: 52)
    }
    
    @objc private func didTapRegister(){
        emailTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
        vaildFields()
    }
    
    private func vaildFields(){
        guard let firstName = firstNameTextField.text, !firstName.isEmpty, let lastName = lastNameTextField.text, !lastName.isEmpty, let email = emailTextField.text, !email.isEmpty, let password = passwordTextField.text, !password.isEmpty, password.count >= 6 else {
            alertError(title: "problem happend!", message: "please, enter all information to register...")
            return
        }
        spinner.show(in: view)
        // register with firebase
        DatabaseManager.shared.checkIfUserExist(email: email) { [weak self] isExist in
            guard let self = self else{return}
            guard !isExist else {
                //user alrady exsist
                self.alertError(title: "problem happend!", message: "this email alrady exsist..")
                return
            }
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { result, erorr in
                guard result != nil ,erorr == nil else{
                    print("error when register")
                    return
                }
                
               /* UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")*/
                
                DispatchQueue.main.async {
                    self.spinner.dismiss()
                }
                let user = UserModel(firstName: firstName, lastName: lastName, email: email)
                DatabaseManager.shared.insertNewUser(user: user) { (success) in
                    if success{
                        //if success upload profile picture
                        UserDefaults.standard.set(email, forKey: "email")
                        UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
                        guard let image = self.profileImageView.image, let data = image.pngData() else {return}
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
                    }
                }
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @objc private func didTapProfileImage(){
        presentProfilePicActionSheet()
    }
}
extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstNameTextField{
            lastNameTextField.becomeFirstResponder()
        }
        else if textField == lastNameTextField{
            emailTextField.becomeFirstResponder()
        }
        else if textField == emailTextField{
            passwordTextField.becomeFirstResponder()
        }
        else if textField == passwordTextField{
            didTapRegister()
        }
        return true
    }
}

extension RegisterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    private func presentProfilePicActionSheet(){
        let sheet = UIAlertController(title: "Profile Picture", message: "How would like to profile picture?", preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (_) in
            self.presentCamera()
        }))
        sheet.addAction(UIAlertAction(title: "Choose Picture", style: .default, handler: { (_) in
            self.presentPhotoLibrary()
        }))
        sheet.addAction(UIAlertAction(title: "cancel", style: .cancel, handler: nil))
        present(sheet, animated: true)
    }
    
    private func presentCamera(){
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func presentPhotoLibrary(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let photoSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else{return}
        self.profileImageView.image = photoSelected
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
