//
//  NewConversationViewController.swift
//  Messenger
//
//  Created by Ahmed Nasr on 5/8/21.
//
import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    var hasFetch = false
    var users = [[String: String]]()
    var results = [SearchResult]()
    
    public var completion: ((SearchResult)->(Void))?
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "searching..."
        return searchBar
    }()
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.isHidden = true
        table.register(NewConversationCell.self, forCellReuseIdentifier: NewConversationCell.identfire)
        return table
    }()
    
    private let noResultsLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.text = "No Results"
        label.textAlignment = .center
        label.textColor = .blue
        label.font = .systemFont(ofSize: 21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame = view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    
    private func setup(){
        view.backgroundColor = .systemBackground
        view.addSubview(tableView)
        view.addSubview(noResultsLabel)
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        navigationController?.navigationBar.topItem?.titleView = searchBar
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(didTapCancelButton))
        searchBar.becomeFirstResponder()
    }
    
    @objc private func didTapCancelButton(){
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = results[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: NewConversationCell.identfire, for: indexPath) as! NewConversationCell
        
        cell.configure(model: model)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let selectUser = results[indexPath.row]
        dismiss(animated: true) {
            self.completion?(selectUser)
        }
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }
}

extension NewConversationViewController: UISearchBarDelegate{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text = searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else {
            return
        }
        searchBar.resignFirstResponder()
        spinner.show(in: view)
        self.searchUsers(text: text)
    }
    
    private func searchUsers(text: String){
        if hasFetch{
            //have data -> filter
            filterUsers(term: text)
        }else{
            DatabaseManager.shared.getAllUsers {[weak self] (result) in
                switch result{
                case .failure(_):
                    print("failed to get users")
                case .success(let users):
                    self?.hasFetch = true
                    self?.users = users
                    //filter data
                    self?.filterUsers(term: text)
                }
            }
        }
    }
    
    private func filterUsers(term: String){
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String, hasFetch else {return}
        
        let safeEmail = DatabaseManager.getSafeEmail(email: currentUserEmail)
        
        self.spinner.dismiss()
        let results: [SearchResult] = self.users.filter({
            guard let email = $0["email"], email != safeEmail else {return false}
            guard let name = $0["name"]?.lowercased() else {
                return false
            }
            return name.hasPrefix(term.lowercased())
        }).compactMap({
            guard let email = $0["email"], let name = $0["name"] else {return nil}
            return SearchResult(name: name, email: email)
        })
        self.results = results
        updateUI()
    }
    
    private func updateUI(){
        if results.isEmpty{
            self.noResultsLabel.isHidden = false
            self.tableView.isHidden = true
        }else{
            self.noResultsLabel.isHidden = true
            self.tableView.isHidden = false
            self.tableView.reloadData()
        }
    }
}

struct SearchResult {
    let name: String
    let email: String
}
