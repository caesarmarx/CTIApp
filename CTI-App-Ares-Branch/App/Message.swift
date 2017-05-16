//
//  Message.swift
//  CTI Translators
//
//  Created by Adeo
//  Copyright © 2016 CTI. All rights reserved.
//

import Foundation
import UIKit
import JSQMessagesViewController

class Message : NSObject, JSQMessageData {
    /**
     *  @return An integer that can be used as a table address in a hash table structure.
     *
     *  @discussion This value must be unique for each message with distinct contents. 
     *  This value is used to cache layout information in the collection view.
     */
    public func messageHash() -> UInt {
        return UInt(0)
    }

    
    /**
     *  This method is used to determine if the message data item contains text or media.
     *  If this method returns `YES`, an instance of `JSQMessagesViewController` will ignore 
     *  the `text` method of this protocol when dequeuing a `JSQMessagesCollectionViewCell`
     *  and only call the `media` method. 
     *
     *  Similarly, if this method returns `NO` then the `media` method will be ignored and
     *  and only the `text` method will be called.
     *
     *  @return A boolean value specifying whether or not this is a media message or a text message.
     *  Return `YES` if this item is a media message, and `NO` if it is a text message.
     */
    public func isMediaMessage() -> Bool {
        return false
    }

    
    /**
     *  @return The display name for the user who sent the message.
     *
     *  @warning You must not return `nil` from this method.
     */
    public func senderDisplayName() -> String! {
        return "";
    }

    var text_: String
    var sender_: String
    var date_: Date
    var imageUrl_: String?
    
    convenience init(text: String?, sender: String?) {
        self.init(text: text, sender: sender, imageUrl: nil)
    }
    
    init(text: String?, sender: String?, imageUrl: String?) {
        self.text_ = text!
        self.sender_ = sender!
        self.date_ = Date()
        self.imageUrl_ = imageUrl
    }
    
    func text() -> String! {
        return text_;
    }
    
    func sender() -> String! {
        return sender_;
    }
    
    func date() -> Date! {
        return date_;
    }
    
    func imageUrl() -> String? {
        return imageUrl_;
    }
    
    func senderId() -> String! {
        return sender_;
    }
}
