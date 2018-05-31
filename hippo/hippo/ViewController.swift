//
//  ViewController.swift
//  hippo
//
//  Created by 张旭 on 2018/5/31.
//  Copyright © 2018 张旭. All rights reserved.
//

import UIKit
import NetworkExtension

class ViewController: UIViewController {

    @IBOutlet var connectButton: UIButton!
    
    var status: VPNStatus {
        didSet(o) {
            updateConnectButton()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.status = .off
        super.init(coder: aDecoder)
        NotificationCenter.default.addObserver(self, selector: #selector(onVPNStatusChanged), name: NSNotification.Name(rawValue: kProxyServiceVPNStatusNotification), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("viewDidLoad")
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func onVPNStatusChanged(){
        self.status = VpnManager.shared.vpnStatus
    }
    
    @IBAction func connectTap(_ sender: AnyObject) {
        NSLog("connect tap")
        if(VpnManager.shared.vpnStatus == .off){
            VpnManager.shared.connect()
        }else{
            VpnManager.shared.disconnect()
        }
    }
    
    func updateConnectButton(){
        switch status {
        case .connecting:
            connectButton.setTitle("connecting", for: UIControlState())
        case .disconnecting:
            connectButton.setTitle("disconnect", for: UIControlState())
        case .on:
            connectButton.setTitle("Disconnect", for: UIControlState())
        case .off:
            connectButton.setTitle("Connect", for: UIControlState())
            
        }
        connectButton.isEnabled = [VPNStatus.on,VPNStatus.off].contains(VpnManager.shared.vpnStatus)
        
        
    }
}

