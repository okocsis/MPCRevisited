import UIKit
import MultipeerConnectivity


protocol MPCManagerDelegate {
    
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String, invitationHandler: ((Bool, MCSession)->Void))
    func connectedWithPeer(peerID: MCPeerID)
}

protocol MPCManagerRecievedMessageDelegate {
    
    func managerRecievedData(data:NSData ,fromPeer peer:MCPeerID)
    
    func managerDidRecievedMessage(message:String,fromPeer:MCPeerID)
    func managerDidEndChat(fromPeer:MCPeerID)
    
}


class MPCManager : NSObject {
    
    static let sharedInstance = MPCManager()

    var delegate: MPCManagerDelegate?
    var messageRecievedDelegate: MPCManagerRecievedMessageDelegate?
    var session: MCSession!
    var peer: MCPeerID!
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var foundPeers = [MCPeerID]()
    
    let dateFormatter = NSDateFormatter()
    
//    var invitationHandler: ((Bool, MCSession)->Void)!
    
    
    private override init () {
        super.init()
        
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        
        self.peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        self.session = MCSession(peer: peer)
        self.session.delegate = self
        
        self.browser = MCNearbyServiceBrowser(peer: peer, serviceType: "appcoda-mpc")
        self.browser.delegate = self
        
        self.advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "appcoda-mpc")
        self.advertiser.delegate = self
    }
    
    
    
    // MARK: Custom method implementation
    
    func sendData(dictionaryWithData dictionary: [String : String], toPeer targetPeer: MCPeerID) -> Bool {
        
        var dictCopy: [String: AnyObject] = dictionary
        let now = NSDate()
        dictCopy["timestamp"] = self.dateFormatter.stringFromDate(now)
        
        let dataToSend = NSKeyedArchiver.archivedDataWithRootObject(dictCopy)
        let peersArray = [targetPeer]
        var success = true
        
        do {
            try self.session.sendData(dataToSend, toPeers: peersArray, withMode: .Reliable)
        } catch let error as NSError {
            print(error.localizedDescription)
            success = false
        }
        
        
        return success
    }
    
}
// MARK: MCNearbyServiceBrowserDelegate method implementation
extension MPCManager : MCNearbyServiceBrowserDelegate {
   
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        
        self.foundPeers.append(peerID)
        
        dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
            self.delegate?.foundPeer()
        }
        
    }
    
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        
        self.foundPeers = self.foundPeers.filter { (aPeer) -> Bool in
            aPeer != peerID
        }

        dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
            self.delegate?.lostPeer()
        }
        
    }
    
    
    func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
        print(error.localizedDescription)
    }

}

// MARK: MCNearbyServiceAdvertiserDelegate method implementation
extension MPCManager : MCNearbyServiceAdvertiserDelegate {
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        
        dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
            
            self.delegate?.invitationWasReceived(peerID.displayName,invitationHandler: invitationHandler)
            
        }
        
        
    }
    
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
        print(error.localizedDescription)
    }
}
// MARK: MCSessionDelegate method implementation
extension MPCManager : MCSessionDelegate {
    
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case .Connected:
            print("Connected to session: \(session)")
            dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
                self.delegate?.connectedWithPeer(peerID)
            }
            
        case .Connecting:
            print("Connecting to session: \(session)")
        case .NotConnected:
            print("Did not connect to session: \(session)")
        }
    }
    
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.messageRecievedDelegate?.managerRecievedData(data, fromPeer: peerID)
        }
        
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String : AnyObject]
        
        

        
        if let oldTimeStamp = dataDictionary["timestamp"] as? String,
            oldDate = self.dateFormatter.dateFromString(oldTimeStamp) {
            
            
            let now = NSDate()
            
            let timeInterval = now.timeIntervalSinceDate(oldDate)
            
            print("Time \(timeInterval) seconds");
        }
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] as? String {
            // Make sure that the message is other than "_end_chat_".
            if message != "_end_chat_"{
                
                dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
                    self.messageRecievedDelegate?.managerDidRecievedMessage(message, fromPeer: peerID)
                }
                
            } else {
                dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
                    self.messageRecievedDelegate?.managerDidEndChat(peerID)
                }
                
            }
        }
        
    }
    
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    
    }
}
