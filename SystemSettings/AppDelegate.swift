//
// Created by Arun Sivakumar on 17/11/18.
// Copyright © 2018 Arun Sivakumar. All rights reserved.
// 


import Cocoa
import SystemConfiguration

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let ip:String = "127.0.0.1"
    private let port:NSNumber = 8080
    
    private var authRef: AuthorizationRef?
    private let statusItem = NSStatusBar.system.statusItem(withLength: 20)
    
    private func creaBtn() {
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("menu"))
        }
    }
    
    private func setUp() {
        authorize()
        constructMenu()
    }
    
    private let off = NSMenuItem(title: "Proxy Off", action: #selector(disableSocksProxy), keyEquivalent: "p")
    private let on = NSMenuItem(title: "Proxy On", action: #selector(enableSocksProxy), keyEquivalent: "o")
    
    private func constructMenu() {
        let menu = NSMenu()
        menu.addItem(on)
        menu.addItem(off)
        off.state = .on
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    
    @objc func enableSocksProxy() {
        on.state = .on
        off.state = .off
        socksProxySet(enabled: true)
    }
    
    @objc func disableSocksProxy() {
        on.state = .off
        off.state = .on
        socksProxySet(enabled: false)
    }
    
    private func socksProxySet(enabled: Bool) {
        
        let prefRef = SCPreferencesCreateWithAuthorization(kCFAllocatorDefault, "systemProxySet" as CFString, nil, self.authRef)!
        let sets = SCPreferencesGetValue(prefRef, kSCPrefNetworkServices)!
        
        var proxies = [NSObject: AnyObject]()
        
        // proxy enabled set
        if enabled {
            proxies[kCFNetworkProxiesHTTPEnable] = 1 as NSNumber
            proxies[kCFNetworkProxiesHTTPSEnable] = 1 as NSNumber
            proxies[kCFNetworkProxiesHTTPProxy] = ip as AnyObject?
            proxies[kCFNetworkProxiesHTTPPort] = port as NSNumber
            proxies[kCFNetworkProxiesHTTPSProxy] = ip as AnyObject?
            proxies[kCFNetworkProxiesHTTPSPort] = port as NSNumber
            proxies[kCFNetworkProxiesExcludeSimpleHostnames] = 1 as NSNumber
        } else {
            proxies[kCFNetworkProxiesHTTPEnable] = 0 as NSNumber
            proxies[kCFNetworkProxiesHTTPSEnable] = 0 as NSNumber
        }
        
        sets.allKeys!.forEach { (key) in
            let dict = sets.object(forKey: key)!
            let hardware = (dict as AnyObject).value(forKeyPath: "Interface.Hardware")
            
            if hardware != nil && ["AirPort","Wi-Fi","Ethernet"].contains(hardware as! String) {
                SCPreferencesPathSetValue(prefRef, "/\(kSCPrefNetworkServices)/\(key)/\(kSCEntNetProxies)" as CFString, proxies as CFDictionary)
            }
        }
        
        // commit to system preferences.
        let commitRet = SCPreferencesCommitChanges(prefRef)
        let applyRet = SCPreferencesApplyChanges(prefRef)
        SCPreferencesSynchronize(prefRef)
        
        Swift.print("after SCPreferencesCommitChanges: commitRet = \(commitRet), applyRet = \(applyRet)")
    }
    
    private func authorize(){
        let error = AuthorizationCreate(nil, nil, [], &authRef)
        assert(error == errAuthorizationSuccess)
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        creaBtn()
        setUp()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
}


