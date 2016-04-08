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
    
    var socket: SocketIOClient = SocketIOClient(socketURL: NSURL(string: "http://172.20.10.2:4000")!)
    
    override init() {
        super.init()
    }
    
    func establishConnection() {
        socket.connect()
    }
    
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func sendHeartRate(time: String, date: String, hr: Double) {
        socket.emit("heartRate", time, date, hr)
    }

}
