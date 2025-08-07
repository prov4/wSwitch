//
//  WindowHandler.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Foundation
import AppKit
import ApplicationServices

struct WindowInfo {
    let title: String
    let app: NSRunningApplication
    let windowRef: AXUIElement?
}

class WindowHandler {
    
    func getAllWindows() -> [WindowInfo] {
        var allWindowInfos: [WindowInfo] = []
        let apps = NSWorkspace.shared.runningApplications
        
        for app in apps {
            guard let appName = app.localizedName,
                  app.activationPolicy == .regular,
                  let windowsForApp = getWindowsForApp(app) else {
                continue
            }
            
            for windowInfo in windowsForApp {
                allWindowInfos.append(windowInfo)
            }
        }
        
        return allWindowInfos
    }
    
    private func getWindowsForApp(_ app: NSRunningApplication) -> [WindowInfo]? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var windowRefs: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowRefs)
        
        guard result == .success,
              let windows = windowRefs as? [AXUIElement] else {
            return nil
        }
        
        var windowInfos: [WindowInfo] = []
        
        for window in windows {
            var titleRef: CFTypeRef?
            let titleResult = AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
            
            if titleResult == .success,
               let title = titleRef as? String,
               !title.isEmpty {
                let windowInfo = WindowInfo(
                    title: "\(title) - \(app.localizedName ?? "")",
                    app: app,
                    windowRef: window
                )
                windowInfos.append(windowInfo)
            }
        }
        
        return windowInfos
    }
    
    func focusWindow(_ windowInfo: WindowInfo) {
        // First activate the app
        windowInfo.app.activate(options: [.activateIgnoringOtherApps])
        
        // Then raise the specific window
        if let window = windowInfo.windowRef {
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
    }
    
    // Keep the old method for backwards compatibility
    func getWindowList() -> Dictionary<String, NSRunningApplication> {
        var runningApps: Dictionary<String, NSRunningApplication> = [:]
        let apps = NSWorkspace.shared.runningApplications
        
        for a in apps {
            let name = a.localizedName ?? "Undefined"
            if a.icon != nil && !containsSpecialCharacters(in: name) {
                runningApps.updateValue(a, forKey: name)
            }
        }

        return runningApps
    }
    
    func containsSpecialCharacters(in string: String) -> Bool {
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?/~`")
        return string.rangeOfCharacter(from: specialCharacters) != nil
    }
}
