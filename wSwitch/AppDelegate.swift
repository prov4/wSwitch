//
//  AppDelegate.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {


    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApplication.shared.delegate = self
        if let window = NSApplication.shared.mainWindow {
            window.center()
            window.isReleasedWhenClosed = false
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
            // Bring app window when dock icon gets clicked
            if !flag {
                for window: AnyObject in sender.windows {
                    window.makeKeyAndOrderFront(self)
                }
            }
            
            return true
    }

}

