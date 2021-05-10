//
//  ProfileViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/7/21.
//
import UIKit
import FirebaseAuth
import FBSDKLoginKit
import GoogleSignIn

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let data = ["Log Out"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
    }
    
    private func setUpTableView(){
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = createHeader()
        
    }
    
    private func createHeader() -> UIView?{
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {return nil}
        let safeEmail = DatabaseManager.getSafeEmail(email: email).self
        let fileName = safeEmail + "_profile_picture.png"
        let path = "images/"+fileName //images -> safeEmail_profile_picture.png
        
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.width, height: 300))
        headerView.backgroundColor = .gray
        let profileImage = UIImageView(frame: CGRect(x: (headerView.width - 150) / 2, y: 75, width: 150, height: 150))
        profileImage.contentMode = .scaleAspectFill
        profileImage.backgroundColor = .white
        profileImage.layer.borderWidth = 3
        profileImage.layer.borderColor = UIColor.white.cgColor
        profileImage.layer.cornerRadius = profileImage.width / 2
        profileImage.clipsToBounds = true
        headerView.addSubview(profileImage)
        
        StorageManager.shared.downloadUrl(path: path) { [weak self] (result) in
            guard let strongself = self else{return}
            switch result{
            case .failure(_):
                print("failed to ger url for profile picture")
            case .success(let url):
                //downaload image
                strongself.downloadImage(ProfileImage: profileImage, url: url)
            }
        }
        return headerView
    }
    
    func downloadImage(ProfileImage: UIImageView, url: URL){
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data, error == nil else{return}
            DispatchQueue.main.async {
                let image = UIImage(data: data)
                ProfileImage.image = image
            }
        }.resume()
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentAlertForLogOut()
    }
    
    private func presentAlertForLogOut(){
        let alert = UIAlertController(title: "", message: "would you like Log Out??", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Log Out", style: .default, handler: { [weak self] (_) in
            guard let strongSelf = self else {return}
            //Log out
            strongSelf.logOut()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    private func logOut(){
        // Log Out facebook
        FBSDKLoginKit.LoginManager().logOut()
        // Log Out Google
        GIDSignIn.sharedInstance()?.signOut()
        do{
            try FirebaseAuth.Auth.auth().signOut()
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }catch{
            print("field when sign out")
        }
    }
}
