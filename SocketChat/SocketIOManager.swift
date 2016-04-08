//
//  SocketIOManager.swift
//  SocketChat
//
//  Created by Nithin Reddy Gaddam on 3/22/16.
//  Copyright © 2016 Nithin Reddy Gaddam. All rights reserved.
//

import UIKit

class SocketIOManager: NSObject {
    
    //Singleton
    static let sharedInstance = SocketIOManager()
    
    var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://192.168.1.6:4000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func sendMessage(message: String, withNickname nickname: String) {
        socket.emit("chatMessage", nickname, message)
    }
    
    func getChatMessage(completionHandler: (messageInfo: [String: AnyObject]) -> Void) {
        socket.on("newChatMessage") { (dataArray, socketAck) -> Void in
            var messageDictionary = [String: AnyObject]()
            messageDictionary["nickname"] = dataArray[0] as! String
            messageDictionary["message"] = dataArray[1] as! String
            messageDictionary["date"] = dataArray[2] as! String
            
            completionHandler(messageInfo: messageDictionary)
        }
    }
    
    func connectToServerWithNickname(nickname: String, completionHandler: (userList: [[String: AnyObject]]!) -> Void) {
        socket.emit("connectUser", nickname)
        // this is invoked every time the server sends user list
        socket.on("userList") { ( dataArray, ack) -> Void in
            completionHandler(userList: dataArray[0] as! [[String: AnyObject]])
        }
        // notify if user joined or exited
        listenForOtherMessages()
    }
    
    //for user to exit chat upon request
    func exitChatWithNickname(nickname: String, completionHandler: () -> Void) {
        socket.emit("exitUser", nickname)
        completionHandler()
    }
    
    private func listenForOtherMessages() {
        // the server listens to new users joining
        socket.on("userConnectUpdate") { (dataArray, socketAck) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("userWasConnectedNotification", object: dataArray[0] as! [String: AnyObject])
        }
        // the servers listens to users exiting
        socket.on("userExitUpdate") { (dataArray, socketAck) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("userWasDisconnectedNotification", object: dataArray[0] as! String)
        }
        
        // update when is user is typing
        socket.on("userTypingUpdate") { (dataArray, socketAck) -> Void in
            NSNotificationCenter.defaultCenter().postNotificationName("userTypingNotification", object: dataArray[0] as? [String: AnyObject])
        }
    }
    
    // emits message when user is typing
    func sendStartTypingMessage(nickname: String) {
        socket.emit("startType", nickname)
    }
    
    // emits when user stops typing message
    func sendStopTypingMessage(nickname: String) {
        socket.emit("stopType", nickname)
    }

}
