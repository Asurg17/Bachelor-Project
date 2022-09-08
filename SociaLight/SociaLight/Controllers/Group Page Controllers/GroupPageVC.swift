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
import Photos
import JGProgressHUD

class GroupPageVC: MessagesViewController {
    
    private let groupService = GroupService()
    private let messageService = MessageService()
    private let userService = UserService()
    private let fileService = FileService()
    private var messages = [Message]()
    private var isInputBarButtonItemHidden = true
    private var isSocketClosed = false
    private var selfSender: Sender? {
        let userId = getUserId()

        return Sender(
            imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
            senderId: userId,
            displayName: "Me"
        )
    }
    private var bottomView: UIView?
    
//  Scroll
    private let loader = JGProgressHUD()
    private let refreshControl = UIRefreshControl()
    private var isFirstCall = true
    private var isRefreshingManually = false
    private var hasScrolledToLastItem = false
    private var scrollToLastView = false
    
    
//  Action Buttons
    
    let cameraButton = InputBarButtonItem()
    let imageButton = InputBarButtonItem()
    let microfonButton = InputBarButtonItem()
        
    
//  Audio
    
    var soundRecorder: AVAudioRecorder!
    var soundPlayer: AVAudioPlayer!
    
    open weak var playingCell: AudioMessageCell?
    open var playingMessage: MessageType?
    
    internal var progressTimer: Timer?
    
    public enum PlayerState {
      case playing
      case pause
      case stopped
    }
    
    open private(set) var state: PlayerState = .stopped

// WebSocket
    
    private var webSocket: URLSessionWebSocketTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createWebSocket() // create web socket
        setupViews()
        getGroupTitle()
        
        refreshControl.addTarget(self, action: #selector(didPullToRefresh(_:)), for: .valueChanged)
        refreshControl.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        refreshControl.isUserInteractionEnabled = false
        messagesCollectionView.alwaysBounceVertical = true
        messagesCollectionView.refreshControl = refreshControl
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupBottomViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if isFirstCall {
            loader.textLabel.text = "Loading"
            loader.style = .light
            loader.backgroundColor = .white.withAlphaComponent(1)
            loader.show(in: self.view)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstCall {
            self.getAllGroupMessages()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if soundRecorder != nil {
            soundRecorder.stop()
            soundRecorder = nil
        }
        
        stopAnyOngoingPlaying()
//        close()
    }
    
    //
    
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
        messageInputBar.sendButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        messageInputBar.sendButton.setTitle("", for: .normal)
        //showMessageTimestampOnSwipeLeft = true
        
        
        setupInputButtons()
    }
    
    private func setupInputButtons() {
        if isInputBarButtonItemHidden {
            cameraButton.setSize(CGSize(width: 30, height: 35), animated: false)
            cameraButton.setImage(UIImage(systemName: "camera.fill"), for: .normal)
            cameraButton.tintColor = UIColor.gray
            
            cameraButton.onTouchUpInside { [weak self] _ in
                self?.stopAnyOngoingPlaying()
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
            
            imageButton.setSize(CGSize(width: 30, height: 35), animated: false)
            imageButton.setImage(UIImage(systemName: "photo.fill"), for: .normal)
            imageButton.tintColor = UIColor.gray
            
            imageButton.onTouchUpInside { [weak self] _ in
                self?.stopAnyOngoingPlaying()
                let picker = UIImagePickerController()
                picker.sourceType = .photoLibrary
                picker.delegate = self
                picker.allowsEditing = true
                self?.present(picker, animated: true)
            }
            
            microfonButton.setSize(CGSize(width: 30, height: 35), animated: false)
            microfonButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
            microfonButton.tintColor = UIColor.gray
            microfonButton.titleLabel?.font = .systemFont(ofSize: 15)
            microfonButton.setTitleColor(UIColor.gray, for: .normal)
            
            microfonButton.onTouchUpInside { [weak self] _ in
                self?.stopAnyOngoingPlaying()
                if self?.checkMicrophoneAccess() ?? false {
                    self?.setupRecorder()
                }
            }
            
            messageInputBar.setLeftStackViewWidthConstant(to: 100, animated: true)
            messageInputBar.setStackViewItems([cameraButton, imageButton, microfonButton], forStack: .left, animated: true)
            
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
                self?.messageInputBarResignFirstResponse()
                self?.setupInputButtons()
            }
            
            messageInputBar.setLeftStackViewWidthConstant(to: 35, animated: true)
            messageInputBar.setStackViewItems([actionButton], forStack: .left, animated: true)
            
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
    
    //
    
    func getGroupTitle() {
        let parameters = [
            "userId": getUserId(),
            "groupId": getGroupId()
        ]
        groupService.getGroupTitle(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.title = response
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    // First call -> Get all group messages (gets last 30 messages)
    
    func getAllGroupMessages() {
        print("Star: getAllGroupMessages")
        let parameters = [
            "groupId": getGroupId(),
            "userId": getUserId()
        ]
        
        messageService.getAllGroupMessages(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.isFirstCall = false
                    self.handleGetAllGroupMessagesSuccess(response: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
                self.loader.dismiss(afterDelay: 0.3, animated: true)
                print("End: getAllGroupMessages")
            }
        }
    }
    
    func handleGetAllGroupMessagesSuccess(response: GroupMessages) {
        if !response.messages.isEmpty {
            messages = getCollectionMessages(response: response).collectionMessages
            messagesCollectionView.reloadData()
            messagesCollectionView.scrollToLastItem()
            print("finished handling..")
        }
    }
    
    // Called when socket notifies that new message was added to the group
    
    func getGroupNewMessages() {
        print("Star: getGroupNewMessages")
        let lastMessageUniqueKey = messages.isEmpty ? "0" : messages[messages.count-1].messageUniqueKey
        
        let parameters = [
            "groupId": getGroupId(),
            "userId": getUserId(),
            "lastMessageUniqueKey": lastMessageUniqueKey
        ]
        
        messageService.getGroupNewMessages(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    self.handleGetGroupNewMessagesSuccess(response: response)
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
                print("End: getGroupNewMessages")
            }
        }
    }
    
    func handleGetGroupNewMessagesSuccess(response: GroupMessages) {
        if !response.messages.isEmpty {
            let resp =  getCollectionMessages(response: response)
            messages.append(contentsOf: resp.collectionMessages)
            if resp.containsMyMessages {
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem()
            } else if messages.count > 5 {
                messagesCollectionView.reloadDataAndKeepOffset()
            } else {
                messagesCollectionView.reloadData()
            }
        }
    }
    
    //
    
    func getGroupOldMessages() {
        if !messages.isEmpty {
            let parameters = [
                "groupId": getGroupId(),
                "userId": getUserId(),
                "firstMessageUniqueKey": messages[0].messageUniqueKey
            ]
            
            messageService.getGroupOldMessages(parameters: parameters) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    switch result {
                    case .success(let response):
                        self.handleGetGroupOldMessagesSuccess(response: response)
                    case .failure(let error):
                        self.showWarningAlert(warningText: error.localizedDescription.description)
                    }
                }
            }
        }
    }
    
    func handleGetGroupOldMessagesSuccess(response: GroupMessages) {
        if !response.messages.isEmpty {
            let resp = getCollectionMessages(response: response)
            messages.insert(contentsOf: resp.collectionMessages, at: 0)
            messagesCollectionView.reloadDataAndKeepOffset()
        }
    }
    
    //
    
    func getCollectionMessages(response: GroupMessages) -> GetCollectionMessagesResp {
        var collectionMessages = [Message]()
        var containsMyMessages = false
        for message in response.messages {
            guard let kind = getMessageKind(message: message),
                  let sender = getSender(message: message) else { continue }
            
            if sender.senderId == selfSender?.senderId { containsMyMessages = true }
           
            collectionMessages.append(Message(
                sender: sender,
                messageUniqueKey: message.messageUniqueKey,
                messageId: message.messageId,
                sentDate: GroupPageVC.dateFormatter.date(from: message.sentDate) ?? Date(),
                kind: kind,
                sentDateTimestamp: message.sendDateTimestamp,
                duration: Double(message.duration) ?? 0.0
            ))
        }
        return GetCollectionMessagesResp(collectionMessages: collectionMessages, containsMyMessages: containsMyMessages)
    }
    
    func getSender(message: GroupMessage) -> Sender? {
        return Sender(
            imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + message.senderId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
            senderId: message.senderId,
            displayName: message.senderName
        )
    }
    
    func getMessageKind(message: GroupMessage) -> MessageKind? {
        var messageKind: MessageKind?
        
        if message.messageType == "text" {
            
            messageKind = .text(message.content)
            
        } else if message.messageType == "photo" {
            
            let media = Media(
                url: URL(string: message.content),
                image: nil,
                placeholderImage: UIImage(named: "royal")!,
                size: getMediaMessageSize()
            )
            
            messageKind = .photo(media)
            
        } else if message.messageType == "audio" {
            
            if let audioURL = URL(string: message.content),
               let duration = Float(message.duration) {
                let audio = Audio(
                    url: audioURL,
                    duration: duration,
                    size: getAudioMessageSize(duration: duration)
                )
                
                messageKind = .audio(audio)
            }
        }
        
        return messageKind
    }
    
    //
    
    func createWebSocket() {
        let session = URLSession(
            configuration: .default ,
            delegate: self,
            delegateQueue: OperationQueue()
        )
        
        if let url = URL(string: "ws://\(ServerStruct.serverHost):\(ServerStruct.serverPort)\(Constants.messagesWsEndpoint)\(getUserId())") {
            webSocket = session.webSocketTask(with: url)
            webSocket?.resume()
        }
    }
    
    func ping() {
        webSocket?.sendPing { error in
            if let error = error {
                print(error)
            }
        }
    }
    
    func close() {
        webSocket?.cancel(with: .goingAway, reason: "Close The Connection".data(using: .utf8))
    }
    
    func send() {
    }
    
    func receive() {
        self.webSocket?.receive(completionHandler: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Got Data -> \(data)")
                case .string(_):
                    DispatchQueue.main.sync {
                        self.getGroupNewMessages()
                    }
                default:
                    break
                }
            case .failure(let error):
                print("Received error: \(error)")
            }
            
            self.receive()
        })
    }
    
    //
    
    func getMediaMessageSize() -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        
        return CGSize(width: screenSize.width*Constants.messageWidthMultiplier, height: screenSize.height*Constants.messageHeightMultiplier)
    }
    
    func getAudioMessageSize(duration: Float) -> CGSize {
        let screenSize: CGRect = UIScreen.main.bounds
        let maxWidth = screenSize.width*Constants.messageWidthMultiplier
        let minWidth = Constants.audioMessageMinWidth
        let calculatedWidth = minWidth + ((maxWidth-minWidth)/Constants.messageMaxPartNum) * Double(duration)
        return CGSize(width: Double.minimum(maxWidth, calculatedWidth), height: Constants.audioMessageHeight)
    }
    
    func messageInputBarResignFirstResponse() {
        if messageInputBar.inputTextView.isFirstResponder {
            messageInputBar.inputTextView.resignFirstResponder()
        }
    }
    
    func getDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = paths[0]
        return documentDirectory
    }
    
    //
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("Done")
        hasScrolledToLastItem = true
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if hasScrolledToLastItem {
            if scrollView.contentOffset.y <= ((view.safeAreaInsets.top * -1)) {
                if !isRefreshingManually && !refreshControl.isRefreshing {
                    isRefreshingManually = true
                    refreshControl.refreshManually()
                    getGroupOldMessages()
                }
            } else {
                isRefreshingManually = false
            }
        }
    }
    
    //
    
    @IBAction func setupRecorder() {
        if soundRecorder == nil {
            let recordSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                       AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
                            //AVEncoderBitRateKey: 320000,
                          AVNumberOfChannelsKey: 1,
                                AVSampleRateKey: 44100.0 ] as [String : Any]
            
            let filename = getDirectory().appendingPathComponent("record.m4a")
            
            do {
                soundRecorder = try AVAudioRecorder(url: filename, settings: recordSettings)
                soundRecorder.delegate = self
                            
                microfonButton.setImage(UIImage(systemName: "stop.circle"), for: .normal)
                microfonButton.setTitle("Recording...", for: .normal)
                messageInputBar.setLeftStackViewWidthConstant(to: 150, animated: true)
                messageInputBar.setStackViewItems([microfonButton], forStack: .left, animated: true)
                messageInputBar.inputTextView.isHidden = true
                messageInputBar.sendButton.isHidden = true
                
                soundRecorder.prepareToRecord()
                soundRecorder.record(forDuration: Constants.maimumRecordTime)
            } catch {
                print(error)
            }
        } else {
            soundRecorder.stop()
        }
    }
    
    @IBAction func showGroupInfo() {
        navigateToGrouInfoPage(vc: self)
    }
    
    @IBAction func back() {
        close()
        if UserDefaults.standard.bool(forKey: "isUserGroupMember") {
            navigationController?.popToRootViewController(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }
    
    //
    
    @objc private func didPullToRefresh(_ sender: Any) {
        refreshControl.endRefreshing()
   }
    
    @objc func joinGroup() {
        let userId = getUserId()
        let groupId = getGroupId()
        
        userService.addUserToGroup(userId: userId, groupId: groupId, userRole: Constants.member) { [weak self] result in
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

extension GroupPageVC: URLSessionWebSocketDelegate {

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("Did connect to socket")
        ping()
        receive()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("Disconnect from Server")
        isSocketClosed = true
    }
    
}

extension GroupPageVC: UpdateGroupProtocol {
    func update(groupTitle: String) {
        self.title = groupTitle
    }
}

extension GroupPageVC: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        stopAnyOngoingPlaying()
        messageInputBar.sendButton.isEnabled = true
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
        fileService.uploadImage(imageKey: imageKey, image: image) { [weak self] result in
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
                              messageUniqueKey: "",
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .photo(media),
                              sentDateTimestamp: NSDate().timeIntervalSince1970.description,
                              duration: 0.0)
        
        sendMessage(collectionMessage: message)
    }
}

extension GroupPageVC: AVAudioRecorderDelegate {
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        
        if soundRecorder != nil {
            soundRecorder = nil
        }
        
        microfonButton.setImage(UIImage(systemName: "mic.fill"), for: .normal)
        microfonButton.setTitle("", for: .normal)
        messageInputBar.setLeftStackViewWidthConstant(to: 100, animated: true)
        messageInputBar.setStackViewItems([cameraButton, imageButton, microfonButton], forStack: .left, animated: true)
        messageInputBar.inputTextView.isHidden = false
        messageInputBar.sendButton.isHidden = false
        
        let audioFileUrl = getDirectory().appendingPathComponent("record.m4a")
            
        do {
            let audioData = try Data(contentsOf: audioFileUrl)
            let audioAsset = AVURLAsset.init(url: audioFileUrl, options: nil)
            let duration = ceil(CMTimeGetSeconds(audioAsset.duration))
            
            guard let sender  = self.selfSender,
            let messageId = createMessageId()
            else { return }

            uploadAudio(sender: sender, messageId: messageId, audioData: audioData, duration: duration)
        } catch {
            print(error)
        }
    }
    
    private func uploadAudio(sender: SenderType, messageId: String, audioData: Data, duration: Double) {
        let _ = getUserId()
        
        let audioKey = "in_group_audio_" + messageId.replacingOccurrences(of: " ", with: "-")
        fileService.uploadAudio(audioKey: audioKey, audioData: audioData, duration: duration) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.sendAudioMessage(audioKey: audioKey, sender: sender, messageId: messageId, duration: duration)
                case .failure(let error):
                    self.showWarningAlert(warningText: "Audio upload failed! Error: " + error.localizedDescription.description)
                }
            }
        }
    }
    
    private func sendAudioMessage(audioKey: String, sender: SenderType, messageId: String, duration: Double) {
        
        if let audioURL = URL(string: Constants.getAudioURLPrefix + audioKey) {
            
            let audio = Audio(url: audioURL,
                              duration: Float(duration),
                              size: .zero)
            
            let message = Message(sender: sender,
                                  messageUniqueKey: "",
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .audio(audio),
                                  sentDateTimestamp: NSDate().timeIntervalSince1970.description,
                                  duration: duration)
            
            sendMessage(collectionMessage: message)
        }
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
            messageUniqueKey: "",
            messageId: messageId,
            sentDate: Date(),
            kind: .text(text),
            sentDateTimestamp: NSDate().timeIntervalSince1970.description,
            duration: 0.0
        )

        sendMessage(collectionMessage: collectionMessage)
    }
    
    private func sendMessage(collectionMessage: Message) {
        let message = [
            "messageId": collectionMessage.messageId,
            "type": collectionMessage.kind.description,
            "senderId": collectionMessage.sender.senderId,
            "groupId": getGroupId(),
            "content": getMessageContent(message: collectionMessage),
            "sendDate": GroupPageVC.dateFormatter.string(from: collectionMessage.sentDate),
            "sendDateTimestamp": collectionMessage.sentDateTimestamp,
            "duration": collectionMessage.duration.description
        ]
        
        messageService.sendMessage(message: message) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    self.messageInputBar.inputTextView.text = nil
                case .failure(let error):
                    if error.localizedDescription.contains("removed") {
                        self.showWarningAlertWithHandler(warningText: "You can no longer send messages cause " + error.localizedDescription)
                    } else {
                        self.showWarningAlert(warningText: "Message send failed! Error: " + error.localizedDescription.description)
                        
                    }
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
        case .audio(let audio):
            content = audio.url.absoluteString
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
        let dateString = GroupPageVC.dateFormatter.string(from: Date())
        let newIdentifier = "\(getGroupId())_\(getUserId())_\(dateString)"

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
        case .photo(_):
            guard let imageURL = URL(string: Constants.getImageURLPrefix + "in_group_image_" + message.messageId.replacingOccurrences(of: " ", with: "-"))
            else { return }
            imageView.sd_setImage(with: imageURL)
        default:
            break
        }
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
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        if playingMessage?.messageId == message.messageId,
           let player = soundPlayer {
            playingCell = cell
            cell.progressView.progress = (player.duration == 0) ? 0 : Float(player.currentTime / player.duration)
            cell.playButton.isSelected = (player.isPlaying == true) ? true : false
            guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
                fatalError("MessagesDisplayDelegate has not been set.")
            }
            cell.durationLabel.text = displayDelegate.audioProgressTextFormat(
                Float(player.duration - player.currentTime),
                for: cell,
                in: messagesCollectionView
            )
        }
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSender(at: indexPath) {
            let name = message.sender.senderId == selfSender?.senderId ? "me" : message.sender.displayName
            return NSAttributedString(
                string: name,
                attributes: [
                    NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1),
                    NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ]
            )
        }
        return nil
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return !isPreviousMessageSameSender(at: indexPath) ? 25 : 0
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(
            string: getTimeString(date: message.sentDate),
            attributes: [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10.0),
                NSAttributedString.Key.foregroundColor: UIColor.gray,
            ]
        )
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 20
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if !isPreviousMessageSameSendDate(at: indexPath) {
            return NSAttributedString(
                string: getDateString(date: message.sentDate),
                attributes: [
                  NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15),
                  NSAttributedString.Key.foregroundColor: UIColor.darkGray,
                ]
            )
        }
        return nil
    }
    
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return !isPreviousMessageSameSendDate(at: indexPath) ? 30 : 0
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section-1].sender.senderId
    }
    
    func isPreviousMessageSameSendDate(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return getDateString(date: messages[indexPath.section].sentDate) == getDateString(date: messages[indexPath.section-1].sentDate)
    }
    
    func isNextMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section + 1 < messages.count else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section + 1].sender.senderId
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return message.sender.senderId == selfSender?.senderId ? UIColor.FlatColor.Blue.CuriousBlue : UIColor(red: 230 / 255, green: 230 / 255, blue: 230 / 255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in _: MessagesCollectionView) -> MessageStyle {
        var corners: UIRectCorner = []

        if isFromCurrentSender(message: message) {
            corners.formUnion(.topLeft)
            corners.formUnion(.bottomLeft)
            corners.formUnion(.topRight)
        } else {
            corners.formUnion(.topRight)
            corners.formUnion(.bottomRight)
            corners.formUnion(.topLeft)
        }

        return .custom { view in
            let radius: CGFloat = Constants.messagesCornerRadius
            let path = UIBezierPath(
                roundedRect: view.bounds,
                byRoundingCorners: corners,
                cornerRadii: CGSize(width: radius, height: radius)
            )
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask
        }
    }
}

extension GroupPageVC: MessageCellDelegate, AVAudioPlayerDelegate {
    
    func didTapBackground(in cell: MessageCollectionViewCell) {
        messageInputBarResignFirstResponse()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        messageInputBarResignFirstResponse()
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        switch message.kind {
        case .photo(_):
            guard let imageURL = URL(string: Constants.getImageURLPrefix + "in_group_image_" +  messages[indexPath.section].messageId.replacingOccurrences(of: " ", with: "-")) else { return }
            navigateToImagePage(url: imageURL)
        default:
            break
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        if soundRecorder == nil {
            if state == .stopped {
                playAudio(cell: cell)
            } else if state == .playing {
                if cell == playingCell {
                    pauseAudio(cell: cell)
                    self.messageInputBar.sendButton.isEnabled = true
                } else {
                    stopAnyOngoingPlaying()
                    playAudio(cell: cell)
                }
            } else if state == .pause {
                if cell == playingCell {
                    resumeAudio(cell: cell)
                    self.messageInputBar.sendButton.isEnabled = false
                } else {
                    stopAnyOngoingPlaying()
                    playAudio(cell: cell)
                }
            }
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopAnyOngoingPlaying()
        messageInputBar.sendButton.isEnabled = true
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        stopAnyOngoingPlaying()
    }
    
    private func playAudio(cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else { return }
        let message = messages[indexPath.section]
        let parameters = [
            "audioKey": "in_group_audio_" + message.messageId.replacingOccurrences(of: " ", with: "-")
        ]
        
        fileService.getAudio(parameters: parameters) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    do {
                        let myFileTypeString = String(AVFileType.wav.rawValue)
                        self.soundPlayer = try AVAudioPlayer(data: response, fileTypeHint: myFileTypeString)
                        self.messageInputBarResignFirstResponse()
                        self.messageInputBar.sendButton.isEnabled = false
                        self.soundPlayer.enableRate = true
                        self.soundPlayer.rate = 1.0
                        self.soundPlayer.delegate = self
                        self.soundPlayer.prepareToPlay()
                        self.soundPlayer.play()
                        self.state = .playing
                        self.playingCell = cell
                        if let playingCellIndexPath = self.messagesCollectionView.indexPath(for: cell) {
                            self.playingMessage = self.messages[playingCellIndexPath.section]
                        }
                        cell.playButton.isSelected = true
                        self.startProgressTimer()
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    self.showWarningAlert(warningText: error.localizedDescription.description)
                }
            }
        }
    }
    
    private func pauseAudio(cell: AudioMessageCell) {
        if soundPlayer != nil {
            soundPlayer.pause()
        }
        state = .pause
        cell.playButton.isSelected = false
    }
    
    private func resumeAudio(cell: AudioMessageCell) {
        if soundPlayer != nil {
            soundPlayer.prepareToPlay()
            soundPlayer.play()
            state = .playing
            cell.playButton.isSelected = true
            startProgressTimer()
        }
    }
    
    private func startProgressTimer() {
        progressTimer?.invalidate()
        progressTimer = nil
        progressTimer = Timer.scheduledTimer(
          timeInterval: 0.1,
          target: self,
          selector: #selector(GroupPageVC.didFireProgressTimer(_:)),
          userInfo: nil,
          repeats: true)
    }
    
    private func stopAnyOngoingPlaying() {
        guard let player = soundPlayer else { return }
        player.stop()
        state = .stopped
        
        if let cell = playingCell {
          cell.progressView.progress = 0.0
          cell.playButton.isSelected = false
          guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError("MessagesDisplayDelegate has not been set.")
          }
          cell.durationLabel.text = displayDelegate.audioProgressTextFormat(
            Float(player.duration),
            for: cell,
            in: messagesCollectionView
          )
        }
        progressTimer?.invalidate()
        progressTimer = nil
        soundPlayer = nil
        playingMessage = nil
        playingCell = nil
    }
    
    @objc private func didFireProgressTimer(_: Timer) {
        guard let player = soundPlayer,
              let cell = playingCell else {
          return
        }
        
        if let playingCellIndexPath = messagesCollectionView.indexPath(for: cell) {
            let currentMessage = messages[playingCellIndexPath.section]
            if currentMessage.messageId == playingMessage?.messageId {
                cell.progressView.progress = (player.duration == 0) ? 0 : Float(player.currentTime / player.duration)
                guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
                  fatalError("MessagesDisplayDelegate has not been set.")
                }
                cell.durationLabel.text = displayDelegate.audioProgressTextFormat(
                    Float(player.duration - player.currentTime),
                    for: cell,
                    in: messagesCollectionView
                )
            } else {
                stopAnyOngoingPlaying()
            }
        }
    }
    
}
