//
//  GroupPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.07.22.
//

import UIKit
import KeychainSwift
import SDWebImage
import MessageKit

struct Message: MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

struct Sender: SenderType {
    var imageURL: String
    var senderId: String
    var displayName: String
}

class GroupPageVC: MessagesViewController {
    
    private var bottomView: UIView?
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    private var messages = [Message]()
    private let selfSender = Sender(imageURL: "", senderId: "1", displayName: "Alex")
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group"
        
        setupViews()
        checkGroup(group: group)
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here.")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
        messages.append(
            Message(
                sender: selfSender,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here. Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla Bla bla bla!")
            )
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupBottomViews()
    }
    
    func setupViews() {
        setupMessagesCollectionView()
    }
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }
    
    func setupBottomViews() {
        let isUserGroupMember = UserDefaults.standard.bool(forKey: "isUserGroupMember")
       
        if isUserGroupMember {
            if bottomView != nil {
                bottomView?.isHidden = true
                messagesCollectionView.contentInset.bottom = messagesCollectionView.contentInset.bottom - view.safeAreaInsets.bottom
            }
            messageInputBar.isHidden = false
        } else {
            messageInputBar.isHidden = true
            if bottomView == nil {
                let bottomViewHeight = messagesCollectionView.contentInset.bottom + view.safeAreaInsets.bottom
                
                let screenSize: CGRect = UIScreen.main.bounds
                bottomView = UIView(frame: CGRect(x: 0, y: screenSize.height-bottomViewHeight, width: screenSize.width, height: bottomViewHeight))

                let button = UIButton(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: messagesCollectionView.contentInset.bottom))
                button.setTitle("Join Group", for: .normal)
                button.setTitleColor(UIColor.blue, for: .normal)
                button.addTarget(self, action: #selector(joinGroup), for: .touchUpInside)

                bottomView!.addSubview(button)

                bottomView!.backgroundColor = UIColor.white
                view.addSubview(bottomView!)
                
                messagesCollectionView.contentInset.bottom = bottomViewHeight
            }
        }
    }
    
    func navigateToGrouInfopPage(group: Group) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let groupInfoPagePageController = storyBoard.instantiateViewController(withIdentifier: "GroupInfoPageVC") as! GroupInfoPageVC
        groupInfoPagePageController.delegate = self
        groupInfoPagePageController.group = group
        self.navigationController?.pushViewController(groupInfoPagePageController, animated: true)
    }
    
    @IBAction func showGroupInfo() {
        navigateToGrouInfopPage(group: group!)
    }
    
    @IBAction func back() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    @objc func joinGroup() {
        if let userId = keychain.get(Constants.userIdKey) {
            service.addUserToGroup(userId: userId, groupId: group!.groupId) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(_):
                        UserDefaults.standard.set(true, forKey: "isUserGroupMember")
                        self.setupBottomViews()
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        } else {
            showWarningAlert(warningText: Constants.fatalError)
        }
    }
    
}

extension GroupPageVC: UpdateGroup {
    
    func update(updatedGroup: Group) {
        self.group = updatedGroup
    }
    
}

extension GroupPageVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        return selfSender
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
}
