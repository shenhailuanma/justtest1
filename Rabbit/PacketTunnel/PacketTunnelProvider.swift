//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by 称一称 on 2016/11/18.
//  Copyright © 2016年 yicheng. All rights reserved.
//

import NetworkExtension
import NEKit
import CocoaLumberjackSwift
import Yaml
import SimpleTunnelServices

class PacketTunnelProvider: NEPacketTunnelProvider , TunnelDelegate{
    
    
    var interface: TUNInterface!
    var enablePacketProcessing = false
    
    var proxyPort: Int!
    
    var proxyServer: ProxyServer!
    
    var lastPath:NWPath?
    
    var started:Bool = false
    
    /// A reference to the tunnel object.
    var tunnel: ClientTunnel?
    

	override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
//        let newTunnel = ClientTunnel()
//        newTunnel.delegate = self
//
//        if let error = newTunnel.startTunnel(self) {
//            NSLog("startTunnel error")
////            completionHandler(error as NSError)
//        }
//        else {
//            // Save the completion handler for when the tunnel is fully established.
////            pendingStartCompletion = completionHandler
//            tunnel = newTunnel
//        }
        
        ////////////////==============
        
        DDLog.removeAllLoggers()
        DDLog.add(DDASLLogger.sharedInstance, with: DDLogLevel.info)
        ObserverFactory.currentFactory = DebugObserverFactory()
        
        NSLog("------ startTunnel begin -------")
        
        guard let conf = (protocolConfiguration as! NETunnelProviderProtocol).providerConfiguration else{
            NSLog("[ERROR] No ProtocolConfiguration Found")
            exit(EXIT_FAILURE)
        }
        
        
        let ss_adder = conf["ss_address"] as! String
        NSLog(ss_adder)
        
        let ss_port = conf["ss_port"] as! Int
        let method = conf["ss_method"] as! String
        NSLog(method)

        let password = conf["ss_password"] as!String
                
        // Proxy Adapter
        
        
        // SSR Httpsimple
//        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.HTTPProtocolObfuscater.Factory(hosts:["intl.aliyun.com","cdn.aliyun.com"], customHeader:nil)
        
        
        // Origin
        let obfuscater = ShadowsocksAdapter.ProtocolObfuscater.OriginProtocolObfuscater.Factory()
        
        
        let algorithm:CryptoAlgorithm
        
        switch method{
        case "AES128CFB":algorithm = .AES128CFB
        case "AES192CFB":algorithm = .AES192CFB
        case "AES256CFB":algorithm = .AES256CFB
        case "CHACHA20":algorithm = .CHACHA20
        case "SALSA20":algorithm = .SALSA20
        case "RC4MD5":algorithm = .RC4MD5 
        default:
            fatalError("Undefined algorithm!")
        }
        
        
        let ssAdapterFactory = ShadowsocksAdapterFactory(serverHost: ss_adder, serverPort: ss_port, protocolObfuscaterFactory:obfuscater, cryptorFactory: ShadowsocksAdapter.CryptoStreamProcessor.Factory(password: password, algorithm: algorithm), streamObfuscaterFactory: ShadowsocksAdapter.StreamObfuscater.OriginStreamObfuscater.Factory())
        
        let httpAuth = HTTPAuthentication(username: "shenhailuanma0512@163.com", password: "zx@19861008")
        let httpAdapterFactory = SecureHTTPAdapterFactory(serverHost: "pac.stalker.cc", serverPort: 9008, auth: httpAuth)
      
        
        let directAdapterFactory = DirectAdapterFactory()
        
        //Get lists from conf
        let yaml_str = conf["ymal_conf"] as!String
        let value = try! Yaml.load(yaml_str)
        
        var UserRules:[NEKit.Rule] = []
        
        for each in (value["rule"].array! ){
            let adapter:NEKit.AdapterFactory
            if each["adapter"].string! == "direct"{
                adapter = directAdapterFactory
            }else{
//                adapter = ssAdapterFactory
                adapter = httpAdapterFactory
            }
            
            let ruleType = each["type"].string!
            switch ruleType {
            case "domainlist":
                var rule_array : [NEKit.DomainListRule.MatchCriterion] = []
                for dom in each["criteria"].array!{
                    let raw_dom = dom.string!
                    let index = raw_dom.index(raw_dom.startIndex, offsetBy: 1)
                    let index2 = raw_dom.index(raw_dom.startIndex, offsetBy: 2)
                    let typeStr = raw_dom.substring(to: index)
                    let url = raw_dom.substring(from: index2)
                    
                    if typeStr == "s"{
                        rule_array.append(DomainListRule.MatchCriterion.suffix(url))
                    }else if typeStr == "k"{
                        rule_array.append(DomainListRule.MatchCriterion.keyword(url))
                    }else if typeStr == "p"{
                        rule_array.append(DomainListRule.MatchCriterion.prefix(url))
                    }else if typeStr == "r"{
                        // ToDo:
                        // shoud be complete
                    }
                }
                UserRules.append(DomainListRule(adapterFactory: adapter, criteria: rule_array))
                
                
            case "iplist":
                let ipArray = each["criteria"].array!.map{$0.string!}
                UserRules.append(try! IPRangeListRule(adapterFactory: adapter, ranges: ipArray))
            default:
                break
            }
        }

        
        
        
        /** Rules **/
        
        let chinaRule = CountryRule(countryCode: "CN", match: true, adapterFactory: directAdapterFactory)
        let unKnowLoc = CountryRule(countryCode: "--", match: true, adapterFactory: directAdapterFactory)
//        let dnsFailRule = DNSFailRule(adapterFactory: ssAdapterFactory)
        let dnsFailRule = DNSFailRule(adapterFactory: httpAdapterFactory)
     
//        let allRule = AllRule(adapterFactory: ssAdapterFactory)
        let allRule = AllRule(adapterFactory: httpAdapterFactory)
        
//        UserRules.append(contentsOf: [chinaRule,unKnowLoc,dnsFailRule,allRule, allRuleHttp])
//        UserRules.append(contentsOf: [chinaRule,unKnowLoc,dnsFailRule, allRule])
        UserRules.append(contentsOf: [allRule, dnsFailRule])
        
        let manager = RuleManager(fromRules: UserRules, appendDirect: true)
        
        RuleManager.currentManager = manager
        
        
        
        
        
        /** start a HTTP/SOCKS5 proxy server locally. **/
        
        proxyPort =  9090
//        RawSocketFactory.TunnelProvider = self
        
        // the `tunnelRemoteAddress` is meaningless because we are not creating a tunnel.
        let networkSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "8.8.8.8")
        networkSettings.mtu = 1500
        
        let ipv4Settings = NEIPv4Settings(addresses: ["192.168.218.119"], subnetMasks: ["255.255.255.0"])
        
//        if enablePacketProcessing {
//            NSLog("enablePacketProcessing is ture.")
//        } else {
//            NSLog("enablePacketProcessing is false.")
//        }
        
//        if enablePacketProcessing {
//            ipv4Settings.includedRoutes = [NEIPv4Route.default()]
//            ipv4Settings.excludedRoutes = [
//                NEIPv4Route(destinationAddress: "10.0.0.0", subnetMask: "255.0.0.0"),
//                NEIPv4Route(destinationAddress: "100.64.0.0", subnetMask: "255.192.0.0"),
//                NEIPv4Route(destinationAddress: "127.0.0.0", subnetMask: "255.0.0.0"),
//                NEIPv4Route(destinationAddress: "169.254.0.0", subnetMask: "255.255.0.0"),
//                NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
//                NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
//                NEIPv4Route(destinationAddress: "17.0.0.0", subnetMask: "255.0.0.0"),
//
//            ]
//        }
        
        networkSettings.iPv4Settings = ipv4Settings
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true
        proxySettings.httpServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.httpsEnabled = true
        proxySettings.httpsServer = NEProxyServer(address: "127.0.0.1", port: proxyPort)
        proxySettings.excludeSimpleHostnames = true
        // This will match all domains
        proxySettings.matchDomains = [""]
        proxySettings.exceptionList = [""]
        networkSettings.proxySettings = proxySettings
        
//        if enablePacketProcessing {
//            let DNSSettings = NEDNSSettings(servers: ["198.18.0.1"])
//            DNSSettings.matchDomains = [""]
//            DNSSettings.matchDomainsNoSearch = false
//            networkSettings.dnsSettings = DNSSettings
//        }
        
        setTunnelNetworkSettings(networkSettings) {
            error in
            guard error == nil else {
                DDLogError("Encountered an error setting up the network: \(error.debugDescription)")
                completionHandler(error)
                return
            }
            
            
            if !self.started{
                NSLog("to start new proxyServer")
                self.proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: "127.0.0.1"), port: NEKit.Port(port: UInt16(self.proxyPort)))
                
                try! self.proxyServer.start()
                self.addObserver(self, forKeyPath: "defaultPath", options: .initial, context: nil)
//                self.addObserver(self, forKeyPath: "state", options: .initial, context: nil)
            }else{
                NSLog("to restart proxyServer")
                self.proxyServer.stop()
                try! self.proxyServer.start()
            }
            
            completionHandler(nil)
            
            
//            if self.enablePacketProcessing {
//                if self.started{
//                    self.interface.stop()
//                }
//
//                self.interface = TUNInterface(packetFlow: self.packetFlow)
//
//
//                let fakeIPPool = try! IPPool(range: IPRange(startIP: IPAddress(fromString: "198.18.1.1")!, endIP: IPAddress(fromString: "198.18.255.255")!))
//
//
//                let dnsServer = DNSServer(address: IPAddress(fromString: "198.18.0.1")!, port: NEKit.Port(port: 53), fakeIPPool: fakeIPPool)
//                let resolver = UDPDNSResolver(address: IPAddress(fromString: "114.114.114.114")!, port: NEKit.Port(port: 53))
//                dnsServer.registerResolver(resolver)
//                self.interface.register(stack: dnsServer)
//
//                DNSServer.currentServer = dnsServer
//
//                let udpStack = UDPDirectStack()
//                self.interface.register(stack: udpStack)
//                let tcpStack = TCPStack.stack
//                tcpStack.proxyServer = self.proxyServer
//                self.interface.register(stack:tcpStack)
//                self.interface.start()
//            }
            self.started = true

        }
        
        NSLog("------ startTunnel over -------")
    }
    

	override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
//        if enablePacketProcessing {
//            interface.stop()
//            interface = nil
//            DNSServer.currentServer = nil
//        }
        
        NSLog("====== stopTunnel start ======")
        
        self.started = false
        
        if(proxyServer != nil){
            proxyServer.stop()
            proxyServer = nil
//            RawSocketFactory.TunnelProvider = nil
        }
        completionHandler()
        
        NSLog("====== stopTunnel over ======")
//        exit(EXIT_SUCCESS)
	}
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "defaultPath" {
            NSLog("received observeValue change notifcation, defaultPath changed")
            
            if self.defaultPath?.status == .satisfied && self.defaultPath != lastPath{
                if(lastPath == nil){
                    lastPath = self.defaultPath
                }else{
                    NSLog("received network change notifcation")
                    let delayTime = DispatchTime.now() + Double(Int64(1 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                    DispatchQueue.main.asyncAfter(deadline: delayTime) {
                        self.startTunnel(options: nil){_ in}
                    }
                }
            }else{
                lastPath = defaultPath
            }
        }
        
    }
    
    
    // MARK: TunnelDelegate
    
    /// Handle the event of the tunnel connection being established.
    func tunnelDidOpen(_ targetTunnel: SimpleTunnelServices.Tunnel) {
        // Open the logical flow of packets through the tunnel.
        NSLog("zxzx tunnelDidOpen")
        
    }
    
    /// Handle the event of the tunnel connection being closed.
    func tunnelDidClose(_ targetTunnel: SimpleTunnelServices.Tunnel) {
        NSLog("zxzx tunnelDidClose")
        
    }
    
    func tunnelDidSendConfiguration(_ targetTunnel: SimpleTunnelServices.Tunnel, configuration: [String : AnyObject]) {
        NSLog("zxzx tunnelDidSendConfiguration")
    }


}
