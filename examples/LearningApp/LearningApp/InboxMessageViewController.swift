//
//  CustomEventViewController.swift
//  LearningApp
//
//  Copyright © 2025 Salesforce. All rights reserved.
//

import MarketingCloudSDK
import UIKit

class InboxMessageViewController: UIViewController {
    
    // MARK: - Properties
    
    var onDelete: (([String:Any]) -> Void)?
    var message: [String: Any] = [:]
    var subTitle: String? = ""
    var messageText: String? = ""
    
    private enum Section: Int, CaseIterable {
        case subTitle
        case messageText
        
        var title: String? {
            switch self {
            case .subTitle: return "Sub Title"
            case .messageText: return "Message"
            }
        }
    }
    
    private var tableView: UITableView!
    
   
    // MARK: - Initializers
    
    init(msg: [String:Any]) {
        super.init(nibName: nil, bundle: nil)
        self.message = msg
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MarketingCloudSdk.requestSdk {
            mc in
                mc?.trackMessageOpened(self.message)
        }
        
        title = message["subject"] as! String?
        subTitle = message["inboxSubtitle"] as! String?
        messageText = message["inboxMessage"] as! String?
                
        view.backgroundColor = .white
        
        setupNavigationBar()
        setupTableView()
        setupKeyboardObservers()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardFrame.height, right: 0)
        tableView.contentInset = contentInset
        tableView.scrollIndicatorInsets = contentInset
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        tableView.contentInset = .zero
        tableView.scrollIndicatorInsets = .zero
    }
    
    private func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Delete",
            style: .plain,
            target: self,
            action: #selector(deleteTapped)
        )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Close",
            style: .done,
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    private func setupTableView() {
        tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.keyboardDismissMode = .interactive
        
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "TextFieldCell")
        tableView.register(TextFieldCell.self, forCellReuseIdentifier: "AttributeCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "BasicCell")
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func closeTapped() {
        dismiss(animated: true)
    }
    
    @objc private func deleteTapped() {
        onDelete?(message)
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension InboxMessageViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        
        switch sec {
        case .subTitle: return 1
        case .messageText: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch section {
        case .subTitle:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.configure(placeholder: "none", text: subTitle ?? "") { [weak self] newText in
                self?.subTitle = newText
            }
            return cell
        case .messageText:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TextFieldCell", for: indexPath) as? TextFieldCell else {
                return UITableViewCell()
            }
            cell.configure(placeholder: "none", text: messageText ?? "") { [weak self] newText in
                self?.messageText = newText
            }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
}

extension InboxMessageViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}


