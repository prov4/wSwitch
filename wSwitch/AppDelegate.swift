//
//  AppDelegate.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Cocoa
import Carbon

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var eventMonitor: Any?
    var statusItem: NSStatusItem?
    var mainWindowController: NSWindowController?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApplication.shared.delegate = self
        
        // Check for accessibility permissions
        checkAccessibilityPermissions()
        
        // Setup status bar item (tray icon)
        setupStatusBarItem()
        
        // Configure the main window but keep it hidden
        if let window = NSApplication.shared.windows.first {
            window.isReleasedWhenClosed = false // Important: prevent window from being released
            window.hidesOnDeactivate = false // Don't auto-hide when app loses focus
            window.isMovableByWindowBackground = true
            window.titleVisibility = .hidden
            window.titlebarAppearsTransparent = true
            window.close()
        }
        
        // Store reference to main window controller
        mainWindowController = NSApplication.shared.windows.first?.windowController
        
        // Hide the dock icon - app will run in tray only
        NSApp.setActivationPolicy(.accessory)
        
        // Register global hotkey for Opt+Cmd+E
        registerGlobalHotkey()
    }
    
    func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: "wSwitch")
            button.action = #selector(statusBarButtonClicked(_:))
            button.target = self
        }
        
        // Create menu for status bar item
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showMainWindow), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusItem?.menu = menu
    }
    
    @objc func statusBarButtonClicked(_ sender: Any?) {
        // Left click behavior - you could also show window directly instead of menu
        // showMainWindow()
    }
    
    @objc func showMainWindow() {
        // Show the app in dock when window is visible
        NSApp.setActivationPolicy(.regular)
        
        // Activate the app
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Show and focus the window
        if let window = NSApplication.shared.windows.first {
            // Make window appear on all spaces (Mission Control desktops)
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            
            window.center()
            window.makeKeyAndOrderFront(nil)
            window.level = .floating
            
            // Focus the search field
            if let viewController = window.contentViewController as? ViewController {
                window.makeFirstResponder(viewController.searchField)
                // Refresh window list when showing
                viewController.refreshWindowList()
            }
        }
    }
    
    func hideMainWindow() {
        // Hide window
        NSApplication.shared.windows.first?.close()
        
        // Return to accessory mode (hide from dock)
        NSApp.setActivationPolicy(.accessory)
    }
    
    func registerGlobalHotkey() {
        // Remove any existing monitor
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        
        // Register global event monitor for Opt+Cmd+E
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            self?.handleGlobalKeyboardEvent(event)
        }
        
        // Also register local monitor for when app is active
        NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if self?.handleGlobalKeyboardEvent(event) == true {
                return nil // Consume the event
            }
            return event
        }
    }
    
    @discardableResult
    func handleGlobalKeyboardEvent(_ event: NSEvent) -> Bool {
        // Check for Opt+Cmd+E (keyCode 14 is 'E')
        if event.modifierFlags.contains([.option, .command]) && event.keyCode == 14 {
            showMainWindow()
            return true
        }
        
        // Keep your existing Alt+Tab functionality if desired
        if event.modifierFlags.contains(.option) && event.keyCode == 48 {
            showMainWindow()
            return true
        }
        
        return false
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
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Show window when dock icon is clicked (if visible)
        showMainWindow()
        return true
    }
    
    // Add this to handle when window is closed
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Don't quit when window is closed, just hide to tray
        hideMainWindow()
        return false
    }
}
