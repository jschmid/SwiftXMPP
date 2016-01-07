
//
//  AppDelegate.swift
//  SwiftXMPP
//
//  Created by Felix Grabowski on 10/06/14.
//  Copyright (c) 2014 Felix Grabowski. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, XMPPStreamDelegate {
    
    var window: UIWindow?
    var viewController: BuddyListViewController?
    var password: String = ""
    var isOpen: Bool = false
    var xmppStream: XMPPStream?
     var chatDelegate: ChatDelegate?
     var messageDelegate: MessageDelegate?
    var loginServer: String = ""
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        self.connect()
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
    func setupStream () {
        xmppStream = XMPPStream()
        
        xmppStream!.addDelegate(self, delegateQueue: dispatch_get_main_queue())
    }
    
    func goOffline() {
        let presence = XMPPPresence(type: "unavailable")
        xmppStream!.sendElement(presence)
    }
    
    func goOnline() {
        print("goOnline")
        let presence = XMPPPresence(type: "away")
        xmppStream!.sendElement(presence)
    }
    
    func connect() -> Bool {
        print("connecting")
        setupStream()
    
        //NSUserDefaults.standardUserDefaults().setValue("8grabows@jabber.mafiasi.de", forKey: "userID")
        let b = NSUserDefaults.standardUserDefaults().stringForKey("userID")
        print("user defaults: " + "\(b)")
        
        let jabberID: String? = NSUserDefaults.standardUserDefaults().stringForKey("userID")
        let myPassword: String? = NSUserDefaults.standardUserDefaults().stringForKey("userPassword")
        let server: String? = NSUserDefaults.standardUserDefaults().stringForKey("loginServer")
        if server != nil{
            loginServer = server!
        }
        xmppStream!.hostName = "localhost"
        
        
        if let stream = xmppStream {
            if !stream.isDisconnected() {
                return true
            }
            
            if jabberID == nil || myPassword == nil{
                print("no jabberID set:" + "\(jabberID)")
                print("no password set:" + "\(myPassword)")
                return false
            }
            
            stream.myJID = XMPPJID.jidWithString(jabberID)
            password = myPassword!
            
            var error: NSError?
            do {
                try stream.connectWithTimeout(XMPPStreamTimeoutNone)
            } catch let error1 as NSError {
                error = error1
                let alert = UIAlertController(title: "Alert", message: "Cannot connect to : \(error!.localizedDescription)", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Click", style: UIAlertActionStyle.Default, handler: nil))
                self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
                
                return false
            }
        }
        return true
    }
    
    func disconnect() {
        goOffline()
        xmppStream!.disconnect()
        //    println("disconnecting")
    }
    
    
    func xmppStreamDidConnect(sender: XMPPStream) {
           print("xmppStreamDidConnect")
        isOpen = true
        do {
            try xmppStream!.authenticateWithPassword(password)
            print("authentification successful")
        } catch {
            print("authentification error: \(error)")
        }
    }
    
    func xmppStreamDidAuthenticate(sender: XMPPStream) {
        //    println("didAuthenticate")
        goOnline()
    }
    
    func xmppStream(sender: XMPPStream?, didReceiveMessage: XMPPMessage?) {
        if let message:XMPPMessage = didReceiveMessage {
            //println("message: \(message)")
            if let msg: String = message.elementForName("body")?.stringValue() {
                if let from: String = message.attributeForName("from")?.stringValue() {
                    let m: NSMutableDictionary = [:]
                    m["msg"] = msg
                    m["sender"] = from
                    print("messageReceived")
                    if messageDelegate != nil
                    {
                    messageDelegate!.newMessageReceived(m)
                    }
                }
            } else { return }
        }
    }
    
    func xmppStream(sender: XMPPStream?, didReceivePresence: XMPPPresence?) {
        //    println("didReceivePresence")
        
        if let presence = didReceivePresence {
            let presenceType = presence.type()
            let myUsername = sender?.myJID.user
            let presenceFromUser = presence.from().user
            
         print(chatDelegate)
            if chatDelegate != nil {
                
                if presenceFromUser != myUsername {
                    if presenceType == "available" {
                        chatDelegate?.newBuddyOnLine("\(presenceFromUser)" + "@" + "\(loginServer)")
                    } else if presenceType == "unavailable" {
                        chatDelegate?.buddyWentOffline("\(presenceFromUser)" + "@" + "\(loginServer)")
                    }
                }
            }
            //      println(presenceType)
        }
        
        
    }
    
    
}


