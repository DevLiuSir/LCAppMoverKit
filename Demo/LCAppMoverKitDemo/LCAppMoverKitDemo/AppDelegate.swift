//
//  AppDelegate.swift
//  LCAppMoverKitDemo
//
//  Created by DevLiuSir on 2018/4/26.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        LCAppMoverKit.shared.moveToApplicationsFolderIfNecessary()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

