//
//  ConversationsViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/5/21.
//
import UIKit
import FirebaseAuth

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

class ConversationsViewController: UIViewController {
    
    var arrOfConversations = [Conversation]()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identfire)
        table.isHidden = true
        return table
    }()
    
    private let noConversationLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversation"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(didTapSearchButton))
        view.addSubview(tableView)
        view.addSubview(noConversationLabel)
        setupTableView()
        fetchConversation()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkAuth()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
    }
    
    private func setupTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 120
        tableView.tableFooterView = UIView()
    }
    
    private func checkAuth(){
        if FirebaseAuth.Auth.auth().currentUser == nil{
            let loginVC = LoginViewController()
            let nav = UINavigationController(rootViewController: loginVC)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false)
        }
    }
    
    private func fetchConversation(){
        guard let email = UserDefaults.standard.object(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.getSafeEmail(email: email)
        DatabaseManager.shared.getAllConversations(email: safeEmail) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .failure(let error):
                print("faield to get conversaton: \(error)")
                self.tableView.isHidden = true
                self.noConversationLabel.isHidden = false
            case .success(let conversations):
                guard !conversations.isEmpty else {
                    self.tableView.isHidden = true
                    self.noConversationLabel.isHidden = false
                    return
                }
                self.noConversationLabel.isHidden = true
                self.tableView.isHidden = false
                self.arrOfConversations = conversations
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    @objc private func didTapSearchButton(){
        let vc = NewConversationViewController()
        vc.completion = {[weak self] result in
            print("\(result)")
            self?.createNewConversation(result: result)
        }
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true, completion: nil)
    }
    
    private func createNewConversation(result: [String: String]){
        guard let name = result["name"], let email = result["email"] else {
            return
        }
        let vc = ChatViewController(with: email, id: nil)
        vc.isNewConversation = true
        vc.title = name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ConversationsViewController: UITableViewDelegate, UITableViewDataSource{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrOfConversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identfire, for: indexPath) as! ConversationTableViewCell
        cell.configure(model: arrOfConversations[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = arrOfConversations[indexPath.row]
        let vc = ChatViewController(with: conversation.otherUserEmail, id: conversation.conversationID)
        vc.title = conversation.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
}
