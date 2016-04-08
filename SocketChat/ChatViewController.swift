//
//  ChatViewController.swift
//  SocketChat
//
//  Created by Nithin Reddy Gaddam on 3/28/16.
//  Copyright © 2016 Nithin Reddy Gaddam. All rights reserved.
//

import UIKit

class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var tblChat: UITableView!
    
    @IBOutlet weak var lblOtherUserActivityStatus: UILabel!
    
    @IBOutlet weak var tvMessageEditor: UITextView!
    
    @IBOutlet weak var conBottomEditor: NSLayoutConstraint!
    
    @IBOutlet weak var lblNewsBanner: UILabel!
    
    
    
    var nickname: String!
    
    var chatMessages = [[String: AnyObject]]()
    
    var bannerLabelTimer: NSTimer!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardDidShowNotification:", name: UIKeyboardDidShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleKeyboardDidHideNotification:", name: UIKeyboardDidHideNotification, object: nil)
        
        
        let swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: "dismissKeyboard")
        swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirection.Down
        swipeGestureRecognizer.delegate = self
        view.addGestureRecognizer(swipeGestureRecognizer)
        
        // observe for user entering and exiting
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleConnectedUserUpdateNotification:", name: "userWasConnectedNotification", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleDisconnectedUserUpdateNotification:", name: "userWasDisconnectedNotification", object: nil)
        
        // notify when user is typing
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleUserTypingNotification:", name: "userTypingNotification", object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        configureNewsBannerLabel()
        configureOtherUserActivityLabel()
        
        tvMessageEditor.delegate = self
    }
    
    //Method used to recieve message
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        SocketIOManager.sharedInstance.getChatMessage { (messageInfo) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.chatMessages.append(messageInfo)
                self.tblChat.reloadData()
                //                self.scrollToBottom()
            })
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction Methods
    // Checks weather there is a message to send then sends the message an clears the editor and closes the keyboard
    @IBAction func sendMessage(sender: AnyObject) {
        if tvMessageEditor.text.characters.count > 0 {
            SocketIOManager.sharedInstance.sendMessage(tvMessageEditor.text!, withNickname: nickname)
            tvMessageEditor.text = ""
            tvMessageEditor.resignFirstResponder()
        }
    }

    
    // MARK: Custom Methods
    
    // only notifies to other users when the current user is typing ans sends a dictionary from the server
    func handleUserTypingNotification(notification: NSNotification) {
        if let typingUsersDictionary = notification.object as? [String: AnyObject] {
            var names = ""
            var totalTypingUsers = 0
            for (typingUser, _) in typingUsersDictionary {
                if typingUser != nickname {
                    names = (names == "") ? typingUser : "\(names), \(typingUser)"
                    totalTypingUsers += 1
                }
            }
            
            if totalTypingUsers > 0 {
                let verb = (totalTypingUsers == 1) ? "is" : "are"
                
                lblOtherUserActivityStatus.text = "\(names) \(verb) now typing a message..."
                lblOtherUserActivityStatus.hidden = false
            }
            else {
                lblOtherUserActivityStatus.hidden = true
            }
        }
        
    }
    
    // extract the connected user’s nickname from the notification’s object property
    func handleConnectedUserUpdateNotification(notification: NSNotification) {
        let connectedUserInfo = notification.object as! [String: AnyObject]
        let connectedUserNickname = connectedUserInfo["nickname"] as? String
        lblNewsBanner.text = "User \(connectedUserNickname!.uppercaseString) was just connected."
        showBannerLabelAnimated()
    }
    
    // displays the disconnected user
    func handleDisconnectedUserUpdateNotification(notification: NSNotification) {
        let disconnectedUserNickname = notification.object as! String
        lblNewsBanner.text = "User \(disconnectedUserNickname.uppercaseString) has left."
        showBannerLabelAnimated()
    }
    
    func configureTableView() {
        tblChat.delegate = self
        tblChat.dataSource = self
        tblChat.registerNib(UINib(nibName: "ChatCell", bundle: nil), forCellReuseIdentifier: "idCellChat")
        tblChat.estimatedRowHeight = 90.0
        tblChat.rowHeight = UITableViewAutomaticDimension
        tblChat.tableFooterView = UIView(frame: CGRectZero)
    }
    
    
    func configureNewsBannerLabel() {
        lblNewsBanner.layer.cornerRadius = 15.0
        lblNewsBanner.clipsToBounds = true
        lblNewsBanner.alpha = 0.0
    }
    
    
    func configureOtherUserActivityLabel() {
        lblOtherUserActivityStatus.hidden = true
        lblOtherUserActivityStatus.text = ""
    }
    
    
    func handleKeyboardDidShowNotification(notification: NSNotification) {
        if let userInfo = notification.userInfo {
            if let keyboardFrame = (userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue() {
                conBottomEditor.constant = keyboardFrame.size.height
                view.layoutIfNeeded()
            }
        }
    }
    
    
    func handleKeyboardDidHideNotification(notification: NSNotification) {
        conBottomEditor.constant = 0
        view.layoutIfNeeded()
    }
    
    
    func scrollToBottom() {
        let delay = 0.1 * Double(NSEC_PER_SEC)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay)), dispatch_get_main_queue()) { () -> Void in
            if self.chatMessages.count > 0 {
                let lastRowIndexPath = NSIndexPath(forRow: self.chatMessages.count - 1, inSection: 0)
                self.tblChat.scrollToRowAtIndexPath(lastRowIndexPath, atScrollPosition: UITableViewScrollPosition.Bottom, animated: true)
            }
        }
    }
    
    
    func showBannerLabelAnimated() {
        UIView.animateWithDuration(0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 1.0
            
            }) { (finished) -> Void in
                self.bannerLabelTimer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: "hideBannerLabel", userInfo: nil, repeats: false)
        }
    }
    
    
    func hideBannerLabel() {
        if bannerLabelTimer != nil {
            bannerLabelTimer.invalidate()
            bannerLabelTimer = nil
        }
        
        UIView.animateWithDuration(0.75, animations: { () -> Void in
            self.lblNewsBanner.alpha = 0.0
            
            }) { (finished) -> Void in
        }
    }

    
    
    func dismissKeyboard() {
        if tvMessageEditor.isFirstResponder() {
            tvMessageEditor.resignFirstResponder()
            
            SocketIOManager.sharedInstance.sendStopTypingMessage(nickname)
        }
    }
    
    
    
    // MARK: UITableView Delegate and Datasource Methods
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatMessages.count
    }
    
    //adjusts the recieved messages to left and sent to the right
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("idCellChat", forIndexPath: indexPath) as! ChatCell
        
        let currentChatMessage = chatMessages[indexPath.row]
        let senderNickname = currentChatMessage["nickname"] as! String
        let message = currentChatMessage["message"] as! String
        let messageDate = currentChatMessage["date"] as! String
        
        if senderNickname == nickname {
            cell.lblChatMessage.textAlignment = NSTextAlignment.Right
            cell.lblMessageDetails.textAlignment = NSTextAlignment.Right
            
            cell.lblChatMessage.textColor = lblNewsBanner.backgroundColor
        }
        
        cell.lblChatMessage.text = message
        cell.lblMessageDetails.text = "by \(senderNickname.uppercaseString) @ \(messageDate)"
        
        cell.lblChatMessage.textColor = UIColor.darkGrayColor()
        
        return cell
    }
    
    
    // MARK: UITextViewDelegate Methods
    
    // lets the server know when the user is typing
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        SocketIOManager.sharedInstance.sendStartTypingMessage(nickname)
        
        return true
    }

    
    // MARK: UIGestureRecognizerDelegate Methods
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
