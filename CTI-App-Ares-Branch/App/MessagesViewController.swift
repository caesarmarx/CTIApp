//
//  MessagesViewController.swift
//  App
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController
import Firebase

class MessagesViewController: JSQMessagesViewController
{
    var user: FIRAuth?

    var messages = [Message]()
    var avatars = Dictionary<String, JSQMessagesAvatarImage>()
    //var outgoingBubbleImageView = JSQMessagesBubbleImageFactory.outgoingMessageBubbleImageViewWithColor(UIColor.jsq_messageBubbleLightGrayColor())
    //var incomingBubbleImageView = JSQMessagesBubbleImageFactory.incomingMessageBubbleImageViewWithColor(UIColor.jsq_messageBubbleGreenColor())
    lazy var outgoingBubbleImageView: JSQMessagesBubbleImage = self.setupOutgoingBubble()
    lazy var incomingBubbleImageView: JSQMessagesBubbleImage = self.setupIncomingBubble()
    var senderImageUrl: String!
    var batchMessages = true
    var ref: FIRDatabaseReference!
    var messagesRef: FIRDatabaseReference!
    var receiver : Contact!
    var sender : String!

    func setupFirebase() {
        
        messagesRef = FIRDatabase.database().reference(withPath: "messages")
        
        messagesRef.queryLimited(toLast: 25).observe(FIRDataEventType.childAdded, with: { (snapshot) in
            
            let postDict = snapshot.value as? [String : AnyObject]
            let text = postDict?["text"] as? String
            let sender = postDict?["sender"] as? String
            let imageUrl = postDict?["imageUrl"] as? String
            
            let message = Message(text: text, sender: sender, imageUrl: imageUrl)
            self.messages.append(message)
            self.finishReceivingMessage()
        })
    }
    
    func sendMessage(_ text: String!, sender: String!) {
        messagesRef.childByAutoId().setValue([
            "text":text,
            "sender":sender,
            "imageUrl":senderImageUrl
            ])
    }
    
    func tempSendMessage(_ text: String!, sender: String!) {
        let message = Message(text: text, sender: sender, imageUrl: senderImageUrl)
        messages.append(message)
    }
    
    func setupAvatarImage(_ name: String, imageUrl: String?, incoming: Bool) {
        if let stringUrl = imageUrl {
            if let url = URL(string: stringUrl) {
                if let data = try? Data(contentsOf: url) {
                    let image = UIImage(data: data)
                    let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
                    let avatarImage = JSQMessagesAvatarImageFactory.avatarImage(with: image, diameter: diameter)
                    avatars[name] = avatarImage
                    return
                }
            }
        }
        setupAvatarColor(name, incoming: incoming)
    }
    
    func setupAvatarColor(_ name: String, incoming: Bool) {
        let diameter = incoming ? UInt(collectionView.collectionViewLayout.incomingAvatarViewSize.width) : UInt(collectionView.collectionViewLayout.outgoingAvatarViewSize.width)
        
        let rgbValue = name.hash
        let r = CGFloat(Float((rgbValue & 0xFF0000) >> 16)/255.0)
        let g = CGFloat(Float((rgbValue & 0xFF00) >> 8)/255.0)
        let b = CGFloat(Float(rgbValue & 0xFF)/255.0)
        let color = UIColor(red: r, green: g, blue: b, alpha: 0.5)
        
        let nameLength = name.characters.count
        let initials : String? = name.substring(to: sender.index(sender.startIndex, offsetBy: nameLength))
        let userImage = JSQMessagesAvatarImageFactory.avatarImage(withUserInitials: initials, backgroundColor: color, textColor: UIColor.black, font: UIFont.systemFont(ofSize: CGFloat(13)), diameter: diameter)
        
        avatars[name] = userImage
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        inputToolbar.contentView.leftBarButtonItem = nil
        automaticallyScrollsToMostRecentMessage = true
        
        sender = (sender != nil) ? sender : "Anonymous"
//        let profileImageUrl = user?.provideImageData["cachedUserProfile"]?["profile_image_url_https"] as? String
//        if let urlString = profileImageUrl {
//            setupAvatarImage(sender, imageUrl: urlString as String, incoming: false)
//            senderImageUrl = urlString as String
//        } else {
//            setupAvatarColor(sender, incoming: false)
//            senderImageUrl = ""
//        }
        
        setupFirebase()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if ref != nil {
            
        }
    }
    
    
    func receivedMessagePressed(_ sender: UIBarButtonItem) {
        showTypingIndicator = !showTypingIndicator
        scrollToBottom(animated: true)
    }
    
    func didPressSendButton(_ button: UIButton!, withMessageText text: String!, sender: String!, date: Date!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()

        sendMessage(text, sender: sender)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        print("Camera pressed!")
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    func collectionView(_ collectionView: JSQMessagesCollectionView!, bubbleImageViewForItemAtIndexPath indexPath: IndexPath!) -> UIImageView! {
        let message = messages[indexPath.item]
        
        if message.sender() == sender {
            return UIImageView(image: outgoingBubbleImageView.messageBubbleImage, highlightedImage: outgoingBubbleImageView.messageBubbleHighlightedImage)
        }
        
        return UIImageView(image: incomingBubbleImageView.messageBubbleImage, highlightedImage: incomingBubbleImageView.messageBubbleHighlightedImage)
    }
//    
//    func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageViewForItemAtIndexPath indexPath: IndexPath!) -> UIImageView! {
//        let message = messages[indexPath.item]
//        if let avatar = avatars[message.sender()] {
//            return UIImageView(image: avatar)
//        } else {
//            setupAvatarImage(message.sender(), imageUrl: message.imageUrl(), incoming: true)
//            return UIImageView(image:avatars[message.sender()])
//        }
//    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[indexPath.item]
        if message.sender() == sender {
            cell.textView.textColor = UIColor.black
        } else {
            cell.textView.textColor = UIColor.white
        }
        
        let attributes : [String:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor!, NSUnderlineStyleAttributeName: 1 as AnyObject]
        cell.textView.linkTextAttributes = attributes
        
        return cell
    }
    
    private func setupOutgoingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }
    
    private func setupIncomingBubble() -> JSQMessagesBubbleImage {
        let bubbleImageFactory = JSQMessagesBubbleImageFactory()
        return bubbleImageFactory!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }
    
    
//    func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: IndexPath!) -> NSAttributedString! {
//        let message = messages[indexPath.item];
//        
//        if message.sender() == sender {
//            return nil;
//        }
//        
//        if indexPath.item > 0 {
//            let previousMessage = messages[indexPath.item - 1];
//            if previousMessage.sender() == message.sender() {
//                return nil;
//            }
//        }
//        
//        return NSAttributedString(string:message.sender())
//    }
//    
//    func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: IndexPath!) -> CGFloat {
//        let message = messages[indexPath.item]
//        
//        if message.sender() == sender {
//            return CGFloat(0.0);
//        }
//        
//        if indexPath.item > 0 {
//            let previousMessage = messages[indexPath.item - 1];
//            if previousMessage.sender() == message.sender() {
//                return CGFloat(0.0);
//            }
//        }
//        
//        return kJSQMessagesCollectionViewCellLabelHeightDefault
//    }


}
