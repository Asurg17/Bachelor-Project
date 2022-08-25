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

class GroupPageVC: MessagesViewController {
    
    private var bottomView: UIView?
    
    private let service = Service()
    
    private var messages = [Message]()
    
    private var timer = Timer()
    
    private var didFinishLoadingMessages = false
    
    private var isInputBarButtonItemHidden = true
    
    var group: Group?
    
    // Action Buttons
    let cameraButton = InputBarButtonItem()
    let imageButton = InputBarButtonItem()
    let microfonButton = InputBarButtonItem()
    
    private var selfSender: Sender? {
        let userId = getUserId()

        return Sender(
            imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + userId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
            senderId: userId,
            displayName: "Me"
        )
    }
    
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
        
        if soundRecorder != nil {
            soundRecorder.stop()
            soundRecorder = nil
        }
        
        stopAnyOngoingPlaying()
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
        messageInputBar.sendButton.setImage(UIImage(systemName: "paperplane"), for: .normal)
        messageInputBar.sendButton.setTitle("", for: .normal)
        
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
    
    func checkCameraAccess() -> Bool {
       switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { success in
                ()
            }
            return false
       case .denied, .restricted:
            showWarningAlert(warningText: "Please go to setting and allow camera access!")
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }
    
    func checkMicrophoneAccess() -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            showWarningAlert(warningText: "Please go to setting and allow microphone access!")
            return false
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                ()
            })
            return false
        @unknown default:
            return false
        }
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
            
            guard let kind = messageKind else { continue }
            
            let collectionMessage = Message(
                sender: sender,
                messageId: message.messageId,
                sentDate: GroupPageVC.dateFormatter.date(from: message.sentDate) ?? Date(),
                kind: kind,
                sentDateTimestamp: message.sendDateTimestamp,
                duration: Double(message.duration) ?? 0.0
            )
            
            collectionMessages.append(collectionMessage)
            
        }
        
        messages = collectionMessages
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToLastItem()
        
        didFinishLoadingMessages = true
    }
    
    @objc func listenForNewMessages() {
        if didFinishLoadingMessages {//&& state != .playing {
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
        
        var scrollToLastItem = false
        
        if response.messages.count != 0 {
            for message in response.messages {
                let sender = Sender(
                    imageURL: (Constants.getImageURLPrefix + Constants.userImagePrefix + message.senderId).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "",
                    senderId: message.senderId,
                    displayName: message.senderName
                )
                
                if let selfSender = selfSender, sender.senderId == selfSender.senderId {
                    scrollToLastItem = true
                }
                
                var messageKind: MessageKind?
                
                if message.messageType == "text" {
                    
                    messageKind = .text(message.content)
                    
                } else if message.messageType == "photo" {
                    
                    let media = Media(url: URL(string: message.content),
                                      image: nil,
                                      placeholderImage: UIImage(named: "royal")!,
                                      size: getMediaMessageSize())
                    
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
                
                guard let kind = messageKind else { return }
                
                let collectionMessage = Message(
                    sender: sender,
                    messageId: message.messageId,
                    sentDate: GroupPageVC.dateFormatter.date(from: message.sentDate) ?? Date(),
                    kind: kind,
                    sentDateTimestamp: message.sendDateTimestamp,
                    duration: Double(message.duration) ?? 0.0
                )
                
                messages.append(collectionMessage)
            
            }

            if scrollToLastItem {
                messagesCollectionView.reloadData()
                messagesCollectionView.scrollToLastItem()
            } else {
                messagesCollectionView.reloadDataAndKeepOffset()
            }
        }
    }
    
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
    
    @IBAction func setupRecorder() {
        if soundRecorder == nil {
            let recordSettings = [AVFormatIDKey: kAudioFormatMPEG4AAC,
                       //AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
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
        service.uploadAudio(audioKey: audioKey, audioData: audioData, duration: duration) { [weak self] result in
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
            "groupId": group!.groupId,
            "content": getMessageContent(message: collectionMessage),
            "sendDate": GroupPageVC.dateFormatter.string(from: collectionMessage.sentDate),
            "sendDateTimestamp": collectionMessage.sentDateTimestamp,
            "duration": collectionMessage.duration.description
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
        case .photo(_):
            guard //let imageURL = media.url,
                  let imageURL = URL(string: Constants.getImageURLPrefix + "in_group_image_" + message.messageId.replacingOccurrences(of: " ", with: "-"))
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
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            navigateToImagePage(url: imageUrl)
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
        
        service.getAudio(parameters: parameters) { [weak self] result in
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
//                        cell.delegate?.didStartAudio(in: cell)
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
