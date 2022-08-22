//
//  GroupPageVC.swift
//  SociaLight
//
//  Created by Sandro Surguladze on 19.07.22.
//

import UIKit
import SDWebImage
import MessageKit
import InputBarAccessoryView
import AVFoundation

class GroupPageVC: MessagesViewController {
    
    private var bottomView: UIView?
    
    private let service = Service()
    
    private var messages = [Message]()
    
    private var timer = Timer()
    
    private var didFinishLoadingMessages = false
    
    private var isInputBarButtonItemHidden = true
    
    var group: Group?
    
    
    private var selfSender: Sender? {
        let userId = getUserId()

        return Sender(
            imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
            senderId: userId,
            displayName: "Me"
        )
    }
    
//--------------
    var soundRecorder: AVAudioRecorder!
    var soundPlayer: AVAudioPlayer!
    
    @IBAction func setupRecorder() {
        if soundRecorder == nil {
            let recordSettings = [AVFormatIDKey: kAudioFormatAppleLossless,
                       AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
                            AVEncoderBitRateKey: 320000,
                          AVNumberOfChannelsKey: 1,
                                AVSampleRateKey: 12000 ] as [String : Any]
            
            let filename = getDirectory().appendingPathComponent("record.m4a")
            
            do {
                soundRecorder = try AVAudioRecorder(url: filename, settings: recordSettings)
                soundRecorder.delegate = self
                soundRecorder.record()
            } catch {
                print("Oh noooo")
            }
            
            print("here1")
        } else {
            soundRecorder.stop()
            soundRecorder = nil
            
            print("here2")
        }
    }
    
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
//--------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkGroup(group: group)
        self.title = group!.groupName
        
        setupViews()
        getAllGroupMessages()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
                
        setupBottomViews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // shedule service call
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { _ in
                self.listenForNewMessages()
            })
            let runLoop = RunLoop.current
            runLoop.add(self.timer, forMode: .default)
            runLoop.run()
        }
        
//        messageInputBar.inputTextView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        timer.invalidate()
    }
    
    func setupViews() {
        setupMessagesCollectionView()
    }
    
    func setupMessagesCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        messageInputBar.inputTextView.delegate = self
        
        setupInputButtons()
    }
    
    private func setupInputButtons() {
        if isInputBarButtonItemHidden {
            let cameraButton = InputBarButtonItem()
            cameraButton.setSize(CGSize(width: 30, height: 35), animated: false)
            cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
            cameraButton.tintColor = UIColor.gray
            
            cameraButton.onTouchUpInside { [weak self] _ in
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    if self?.checkCameraAccess() ?? false {
                        let picker = UIImagePickerController()
                        picker.sourceType = .camera
                        picker.delegate = self
                        picker.allowsEditing = true
                        self?.present(picker, animated: true)
                    }
                } else {
                    self?.showWarningAlert(warningText: "Camera is not available on your device")
                }
            }
            
            let imageButton = InputBarButtonItem()
            imageButton.setSize(CGSize(width: 30, height: 35), animated: false)
            imageButton.setImage(UIImage(systemName: "photo.fill"), for: .normal)
            imageButton.tintColor = UIColor.gray
            
            imageButton.onTouchUpInside { [weak self] _ in
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                picker.allowsEditing = true
                self?.present(picker, animated: true)
            }
            
            let microfonButton = InputBarButtonItem()
            microfonButton.setSize(CGSize(width: 30, height: 35), animated: false)
            microfonButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            microfonButton.tintColor = UIColor.gray
            
            microfonButton.onTouchUpInside { [weak self] _ in
                self?.setupRecorder()
            }
            
            messageInputBar.setLeftStackViewWidthConstant(to: 100, animated: false)
            messageInputBar.setStackViewItems([cameraButton, imageButton, microfonButton], forStack: .left, animated: false)
            
            isInputBarButtonItemHidden = false
        }
    }
    
    private func setupActionButton() {
        if !isInputBarButtonItemHidden {
            let actionButton = InputBarButtonItem()
            actionButton.setSize(CGSize(width: 30, height: 35), animated: false)
            actionButton.setImage(UIImage(systemName: "chevron.forward"), for: .normal)
            actionButton.tintColor = UIColor.gray
            
            actionButton.onTouchUpInside { [weak self] _ in
                self?.setupInputButtons()
            }
            
            messageInputBar.setLeftStackViewWidthConstant(to: 35, animated: false)
            messageInputBar.setStackViewItems([actionButton], forStack: .left, animated: false)
            
            isInputBarButtonItemHidden = true
        }
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
    
    func checkCameraAccess() -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            return false
        case .restricted:
            return false
        case .denied:
            showWarningAlert(warningText: "Please go to setting and allow camera access!")
        case .authorized:
            return true
        @unknown default:
            return false
        }
        
        return false
    }
    
    func getAllGroupMessages() {
        let parameters = [
            "groupId": group!.groupId,
            "userId": getUserId()
        ]
        
        service.getAllGroupMessages(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.handleSuccess(response: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    func handleSuccess(response: GroupMessages) {
        var collectionMessages = [Message]()
        for message in response.messages {
            let sender = Sender(
                imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + message.senderId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
                senderId: message.senderId,
                displayName: message.senderName
            )
            
            var messageKind: MessageKind?
            
            if message.messageType == "text" {
                
                messageKind = .text(message.content)
                
            } else if message.messageType == "photo" {
                
                let media = Media(url: URL(string: message.content),
                                  image: nil,
                                  placeholderImage: UIImage(named: "royal")!,
                                  size: getMediaMessageSize())
                
                messageKind = .photo(media)
            }
            
            guard let kind = messageKind else { continue }
            
            let collectionMessage = Message(
                sender: sender,
                messageId: message.messageId,
                sentDate: GroupPageVC.dateFormatter.date(from: message.sentDate) ?? Date(),
                kind: kind,
                sentDateTimestamp: message.sendDateTimestamp
            )
            
            collectionMessages.append(collectionMessage)
            
        }
        
        messages = collectionMessages
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem()
        
        didFinishLoadingMessages = true
    }
    
    @objc func listenForNewMessages() {
        if didFinishLoadingMessages {
            var lastMessageSentDateTimestamp = "0"
                
            if !messages.isEmpty {
                lastMessageSentDateTimestamp = messages[messages.count-1].sentDateTimestamp
            }
            
            let parameters = [
                "groupId": group!.groupId,
                "userId": getUserId(),
                "lastMessageSentDateTimestamp": lastMessageSentDateTimestamp
            ]
            
            service.getNewMessages(parameters: parameters) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.addNewMessagesToCollectionView(response: response)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        }
    }
    
    func addNewMessagesToCollectionView(response: GroupMessages) {
        if response.messages.count != 0 {
            for message in response.messages {
                let sender = Sender(
                    imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + message.senderId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
                    senderId: message.senderId,
                    displayName: message.senderName
                )
                
                var messageKind: MessageKind?
                
                if message.messageType == "text" {
                    
                    messageKind = .text(message.content)
                    
                } else if message.messageType == "photo" {
                    
                    let media = Media(url: URL(string: message.content),
                                      image: nil,
                                      placeholderImage: UIImage(named: "royal")!,
                                      size: getMediaMessageSize())
                    
                    messageKind = .photo(media)
                }
                
                guard let kind = messageKind else { return }
                
                let collectionMessage = Message(
                    sender: sender,
                    messageId: message.messageId,
                    sentDate: GroupPageVC.dateFormatter.date(from: message.sentDate) ?? Date(),
                    kind: kind,
                    sentDateTimestamp: message.sendDateTimestamp
                )
                
                messages.append(collectionMessage)
            
            }

            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem()
        }
    }
    
    func getMediaMessageSize() -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        
        return CGSize(width: screenSize.width*0.7, height: screenSize.height*0.35)
    }
    
    @IBAction func showGroupInfo() {
        navigateToGrouInfoPage(group: group!, vc: self)
    }
    
    @IBAction func back() {
        navigationController?.popToRootViewController(animated: true)
    }
    
    
    @objc func joinGroup() {
        let userId = getUserId()
        
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
    }
    
}

extension GroupPageVC: UpdateGroup {
    
    func update(updatedGroup: Group) {
        self.group = updatedGroup
        self.title = self.group?.groupName
    }
    
}

extension GroupPageVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        setupActionButton()
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        setupInputButtons()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        setupActionButton()
        return true
    }

}

extension GroupPageVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        guard let sender  = self.selfSender,
              let messageId = createMessageId()
        else { return }
                
        if let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            uploadImage(image: image, messageId: messageId, sender: sender)
        }
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func uploadImage(image: UIImage, messageId: String, sender: Sender) {
        let _ = getUserId()
        
        let imageKey = "in_group_image_" + messageId.replacingOccurrences(of: " ", with: "-")
        service.uploadImage(imageKey: imageKey, image: image) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.sendImageMessage(messageId: messageId, sender: sender, imageKey: imageKey)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    private func sendImageMessage(messageId: String, sender: Sender, imageKey: String) {
    
        let media = Media(url: URL(string: Constants.getImageURLPrefix + imageKey),
                          image: nil,
                          placeholderImage: UIImage(),
                          size: .zero)
        
        let message = Message(sender: sender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .photo(media),
                              sentDateTimestamp: NSDate().timeIntervalSince1970.description)
        
        sendMessage(collectionMessage: message)
    }
}

extension GroupPageVC: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
        let sender  = self.selfSender,
        let messageId = createMessageId()
        else { return }
        
        let collectionMessage = Message(
            sender: sender,
            messageId: messageId,
            sentDate: Date(),
            kind: .text(text),
            sentDateTimestamp: NSDate().timeIntervalSince1970.description
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
            "sendDate": GroupPageVC.dateFormatter.string(from: collectionMessage.sentDate),
            "sendDateTimestamp": collectionMessage.sentDateTimestamp
        ]
        
        service.sendMessage(message: message) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.messageInputBar.inputTextView.text = nil
//                    self.messages.append(collectionMessage)
//                    self.messagesCollectionView.reloadData()
//                    self.messagesCollectionView.scrollToLastItem()
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
            content = messageText
        case .attributedText(_):
            break
        case .photo(let media):
            if let url = media.url {
                content = url.absoluteString
            }
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
        let userId = getUserId()

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
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else { return }
        
        switch message.kind {
        case .photo(let media):
            guard let imageURL = media.url else { return }
            imageView.sd_setImage(with: imageURL)
        default:
            break
        }
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        guard let message = message as? Message else { return }
        
        if let avatarImageUrl = (Constants.getImageURLPrefix + Constants.userImagePrefix + message.sender.senderId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            avatarView.sd_setImage(
                with: URL(string: avatarImageUrl),
                completed: { (image, error, cacheType, imageURL) in
                    if image == nil {
                        avatarView.image = UIImage(named: "empty_avatar_image")
                    }
                }
            )
        }
    }
    
}

extension GroupPageVC: MessageCellDelegate {
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            navigateToImagePage(url: imageUrl)
        default:
            break
        }
    }
    
}


extension GroupPageVC: AVAudioPlayerDelegate, AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let documentDirUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioFileUrl = documentDirUrl.appendingPathComponent("record.m4a")
        
        do {
            soundPlayer = try AVAudioPlayer(contentsOf: audioFileUrl)
            soundPlayer.play()
        } catch {
            print(error)
        }
        
        do {
            let audioData = try Data(contentsOf: audioFileUrl)
            let base64audio = audioData.base64EncodedString()
            print(base64audio)
            //...
        } catch {
            print(error)
        }

        print("OKOK")
    }
    
}
