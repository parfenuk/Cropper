//
//  AppDelegate.swift
//  Cropper
//
//  Created by Miraslau Parafeniuk on 28.05.24.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        
        if flag { sender.windows.first?.orderFront(self) }
        else { sender.windows.first?.makeKeyAndOrderFront(self) }
        
        return true
    }
}

