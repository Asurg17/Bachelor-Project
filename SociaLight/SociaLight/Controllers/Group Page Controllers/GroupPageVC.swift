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
import InputBarAccessoryView

class GroupPageVC: MessagesViewController {
    
    private var bottomView: UIView?
    
    private let service = Service()
    private let keychain = KeychainSwift()
    
    private var messages = [Message]()
    
    private var selfSender: Sender? {
        guard let userId = keychain.get(Constants.userIdKey) else {
            return nil
        }

        return Sender(
            imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
            senderId: userId,
            displayName: "My name"
        )
    }
    
    var group: Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Group"
        
        setupViews()
        checkGroup(group: group)
        
        messages.append(
            Message(
                sender: selfSender!,
                messageId: "1",
                sentDate: Date(),
                kind: .text("Hello, this is my first message here.")
            )
        )
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        setupBottomViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    func setupViews() {
        setupMessagesCollectionView()
    }
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
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

extension GroupPageVC: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let sender  = self.selfSender,
        let messageId = createMessageId() else {
             return
        }
        
        let collectionMessage = Message(
            sender: sender,
            messageId: messageId,
            sentDate: Date(),
            kind: .text(text)
        )
        
        sendMessage(collectionMessage: collectionMessage)
    }
    
    private func sendMessage(collectionMessage: Message) {
        let message = [
            "messageId": collectionMessage.messageId,
            "type": collectionMessage.kind.description,
            "senderId": collectionMessage.sender.senderId,
            "groupId": group!.groupId,
            "content": getMessageContent(message: collectionMessage),
            "sendDate": GroupPageVC.dateFormatter.string(from: collectionMessage.sentDate)
        ]
        
        service.sendMessage(message: message) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.messages.append(collectionMessage)
                    self.messagesCollectionView.reloadData()
                case .failure(let error):
                    self.showWarningAlert(warningText: "Message send failed! Error: " + error.localizedDescription.description)
                }
            }
        }
    }
    
    private func getMessageContent(message: Message) -> String {
        var content = ""
        switch message.kind {
        case .text(let messageText):
            content =  messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        
        return content
    }
    
    private func createMessageId() -> String? {
        guard let userId = keychain.get(Constants.userIdKey) else {
            return nil
        }

        let dateString = GroupPageVC.dateFormatter.string(from: Date())
        let newIdentifier = "\(group!.groupId)_\(userId)_\(dateString)"

        return newIdentifier
    }
    
}

extension GroupPageVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        
        fatalError("User can't be validated!")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        messages.count
    }
    
}
