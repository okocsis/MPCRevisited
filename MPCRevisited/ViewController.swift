import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {

    @IBOutlet weak var tblPeers: UITableView!
    
    var isAdvertising: Bool = false
    
    let mpcManager = MPCManager.sharedInstance
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tblPeers.delegate = self
        self.tblPeers.dataSource = self
        
        self.mpcManager.delegate = self
        
        self.mpcManager.browser.startBrowsingForPeers()
        
        self.mpcManager.advertiser.startAdvertisingPeer()
        
        self.isAdvertising = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    // MARK: IBAction method implementation
    
    @IBAction func startStopAdvertising(sender: AnyObject) {
        let actionSheet = UIAlertController(title: "", message: "Change Visibility", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var actionTitle: String
        if self.isAdvertising == true {
            actionTitle = "Make me invisible to others"
        }
        else{
            actionTitle = "Make me visible to others"
        }
        
        let visibilityAction: UIAlertAction = UIAlertAction(title: actionTitle, style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            if self.isAdvertising == true {
                self.mpcManager.advertiser.stopAdvertisingPeer()
            }
            else{
                self.mpcManager.advertiser.startAdvertisingPeer()
            }
            
            self.isAdvertising = !self.isAdvertising
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(visibilityAction)
        actionSheet.addAction(cancelAction)
        
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
    
    
}

extension ViewController : UITableViewDelegate {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60.0
    }
    
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedPeer = self.mpcManager.foundPeers[indexPath.row] as MCPeerID
        
        self.mpcManager.browser.invitePeer(selectedPeer, toSession: self.mpcManager.session, withContext: nil, timeout: 20)
    }
}

extension ViewController : UITableViewDataSource {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.mpcManager.foundPeers.count
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCellWithIdentifier("idCellPeer") else {
            assert(true)
            return UITableViewCell()
        }
        
        cell.textLabel?.text = self.mpcManager.foundPeers[indexPath.row].displayName
        
        return cell
    }
}

extension ViewController : MPCManagerDelegate {
    
    func foundPeer() {
        self.tblPeers.reloadData()
    }
    
    
    func lostPeer() {
        self.tblPeers.reloadData()
    }
    
    func invitationWasReceived(fromPeer: String, invitationHandler: ((Bool, MCSession)->Void)) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertControllerStyle.Alert)
        
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertActionStyle.Default) { (alertAction) -> Void in
            invitationHandler(true, self.mpcManager.session)
        }
        
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (alertAction) -> Void in
            invitationHandler(false, self.mpcManager.session)
        }
        
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
        
        self.presentViewController(alert, animated: true, completion: nil)
        
        
    }
    
    
    func connectedWithPeer(peerID: MCPeerID) {
        
        self.performSegueWithIdentifier("idSegueChat", sender: self)
    }
}

