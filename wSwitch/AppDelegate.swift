//
//  AppDelegate.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        NSApplication.shared.delegate = self
        
        // Check for accessibility permissions
        checkAccessibilityPermissions()
        
        // Activate the app and bring it to front
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Make sure the main window is key and ordered front
        if let window = NSApplication.shared.windows.first {
            window.center()
            window.isReleasedWhenClosed = false
            window.makeKeyAndOrderFront(nil)
            window.level = .floating // Optional: keeps window above others
        }
        
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { (event) in
                self.handleGlobalKeyboardEvent(event)
               }
    }
    
    func checkAccessibilityPermissions() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        
        if !accessEnabled {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "wSwitch needs accessibility permissions to see window titles from other applications. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
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
    
    func handleGlobalKeyboardEvent(_ event: NSEvent) {
        if event.modifierFlags.contains(.option) && event.keyCode == 48 {
            print("Alt + Tab pressed!")
            // Show and focus the window when Alt+Tab is pressed
            NSApplication.shared.activate(ignoringOtherApps: true)
            if let window = NSApplication.shared.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

}
