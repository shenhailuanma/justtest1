//
//  HttpsProxy.swift
//  PacketTunnel
//
//  Created by zhangxu on 2018/6/12.
//  Copyright © 2018 Aofei Sheng. All rights reserved.
//

import NEKit

class HttpsProxy {
//    let serverAddress: String
//    let serverPort: UInt16
    let localAddress: String
    let localPort: UInt16
    
    private let proxyServer: GCDHTTPProxyServer
    
    init(localAddress: String, localPort: UInt16) {
        
        self.localAddress = localAddress
        self.localPort = localPort
        
        proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: localAddress), port: NEKit.Port(port: localPort))
        
        
        let httpAuth = HTTPAuthentication(username: "shenhailuanma0512@163.com", password: "zx@19861008")
        let httpAdapterFactory = SecureHTTPAdapterFactory(serverHost: "pac.stalker.cc", serverPort: 9008, auth: httpAuth)
        
        
        RuleManager.currentManager = RuleManager(
            fromRules: [
                AllRule(adapterFactory: httpAdapterFactory),
                ],
            appendDirect: true
        )
    }
    
    func start() throws {
        
        try proxyServer.start()
    }
    
    func stop() {
        proxyServer.stop()
    }
}
