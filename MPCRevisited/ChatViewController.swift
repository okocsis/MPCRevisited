import UIKit
import MultipeerConnectivity

class ParkBenchTimer {
    
    let startTime:CFAbsoluteTime
    var endTime:CFAbsoluteTime?
    
    init() {
        startTime = CFAbsoluteTimeGetCurrent()
    }
    
    func stop() -> CFAbsoluteTime {
        endTime = CFAbsoluteTimeGetCurrent()
        
        return duration!
    }
    
    var duration:CFAbsoluteTime? {
        if let endTime = endTime {
            return endTime - startTime
        } else {
            return nil
        }
    }
}



class ChatViewController: UIViewController, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var chatTextField: UITextField!
    
    @IBOutlet weak var chatTableView: UITableView!
    
    var messagesArray: [[String : String]] = []
    
    let mpcManager = MPCManager.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.chatTableView.delegate = self
        self.chatTableView.dataSource = self
        
        self.chatTableView.estimatedRowHeight = 60.0
        self.chatTableView.rowHeight = UITableViewAutomaticDimension
        
        self.chatTextField.delegate = self
    
        self.mpcManager.messageRecievedDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    
    // MARK: IBAction method implementation
    
    @IBAction func endChat(sender: AnyObject) {
        let messageDictionary: [String: String] = ["message": "_end_chat_"]
        if self.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: self.mpcManager.session.connectedPeers[0] as MCPeerID){
            self.dismissViewControllerAnimated(true, completion: { () -> Void in
                self.mpcManager.session.disconnect()
            })
        }
    }
    
    
    // MARK: UITableView related method implementation
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.messagesArray.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCellWithIdentifier("idCell") else {
            assert(true)
            return UITableViewCell()
        }
        
        guard let currentMessage = self.messagesArray[safe: indexPath.row] else {
            print(" ")
            assert(true)
            return UITableViewCell()
        }

        if let sender = currentMessage["sender"] {
            var senderLabelText: String
            var senderColor: UIColor
            
            if sender == "self" {
                
                senderLabelText = "I said:"
                senderColor = UIColor.purpleColor()
                
            } else {
                
                senderLabelText = sender + " said:"
                senderColor = UIColor.orangeColor()
                
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
        }
        
        if let message = currentMessage["message"] {
            cell.textLabel?.text = message
        }
        
        return cell
    }
    
    
    
    // MARK: UITextFieldDelegate method implementation
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        guard let textFieldText = textField.text else {
            assert(true)
            return false
        }
        
        
        let messageDictionary: [String: String] = ["message": textFieldText]
        
        guard let connectedPeer = self.mpcManager.session.connectedPeers[safe: 0] else {
            
            print(" ")
            assert(true)
            return false
        }

        if self.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: connectedPeer) {
            
            let dictionary = ["sender": "self", "message": textFieldText]
            self.messagesArray.append(dictionary)
            
            self.updateTableview()
            
        } else {
            
            print("Could not send data")
            
        }
        
        textField.text = ""
        
        return true
    }
    
    
    // MARK: Custom method implementation
    
    func updateTableview(){
        chatTableView.reloadData()
        
        if self.chatTableView.contentSize.height > self.chatTableView.frame.size.height {
            
            let indexPathToScrollTo = NSIndexPath(forRow: messagesArray.count - 1, inSection: 0)
            
            self.chatTableView.scrollToRowAtIndexPath(indexPathToScrollTo, atScrollPosition: .Bottom, animated: true)
        }
    }
    
    
}

extension ChatViewController : MPCManagerRecievedMessageDelegate {
    func managerRecievedData(data:NSData ,fromPeer:MCPeerID) {
        // Convert the data (NSData) into a Dictionary object.
        let dataDictionary = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [String : String]
        
        
        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"] {
            // Make sure that the message is other than "_end_chat_".
            if message != "_end_chat_"{
                
                // Create a new dictionary and set the sender and the received message to it.
                let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
                
                // Add this dictionary to the messagesArray array.
                messagesArray.append(messageDictionary)
                
                // Reload the tableview data and scroll to the bottom using the main thread.
                self.updateTableview()
                
            } else {
                
                
            }
        }
        
    }
    
    func managerDidRecievedMessage(message: String, fromPeer: MCPeerID) {
        // Create a new dictionary and set the sender and the received message to it.
        let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]
        
        // Add this dictionary to the messagesArray array.
        messagesArray.append(messageDictionary)
        
        // Reload the tableview data and scroll to the bottom using the main thread.
        self.updateTableview()
    }
    
    func managerDidEndChat(fromPeer:MCPeerID) {
        
        // In this case an "_end_chat_" message was received.
        // Show an alert view to the user.
        let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            self.mpcManager.session.disconnect()
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(doneAction)
        
        self.presentViewController(alert, animated: true, completion: nil)

    }
}

