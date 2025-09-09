//
//  WindowHandler.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Foundation
import AppKit
import ApplicationServices
import CoreGraphics

struct WindowInfo {
    let title: String
    let app: NSRunningApplication
    let windowRef: AXUIElement?
    let spaceID: Int? // Track which space the window is on
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
        
        // Sort windows - you can customize this
        // This puts windows from current space first, then others
        allWindowInfos.sort { (w1, w2) in
            if let space1 = w1.spaceID, let space2 = w2.spaceID {
                let currentSpace = getCurrentSpaceID()
                if space1 == currentSpace && space2 != currentSpace {
                    return true
                } else if space1 != currentSpace && space2 == currentSpace {
                    return false
                }
            }
            return false
        }
        
        return allWindowInfos
    }
    
    private func getWindowsForApp(_ app: NSRunningApplication) -> [WindowInfo]? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        let allWindows = getAllWindowsAcrossSpaces()        
        
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
            
            // Check if window is minimized
            var minimizedRef: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
            let isMinimized = (minimizedResult == .success) && (minimizedRef as? Bool ?? false)
            
            // Get window subrole to filter out certain window types
            var subroleRef: CFTypeRef?
            _ = AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subroleRef)
            let subrole = subroleRef as? String
            
            // Skip certain window types (like floating panels, tooltips, etc.)
            let skipSubroles = ["AXFloatingWindow", "AXSystemFloatingWindow", "AXTooltip"]
            if let subrole = subrole, skipSubroles.contains(subrole) {
                continue
            }
            
            if titleResult == .success,
               let title = titleRef as? String,
               !title.isEmpty {
                
                // Try to determine which space the window is on
                let spaceID = getWindowSpaceID(window: window)
                
                // Include minimized windows with a marker
                let displayTitle = isMinimized ? "\(title) (minimized) - \(app.localizedName ?? "")" : "\(title) - \(app.localizedName ?? "")"
                
                let windowInfo = WindowInfo(
                    title: displayTitle,
                    app: app,
                    windowRef: window,
                    spaceID: spaceID
                )
                windowInfos.append(windowInfo)
            }
        }
        
        return windowInfos
    }
    
    // Add this method to WindowHandler class:
    private func getAllWindowsAcrossSpaces() -> [(CGWindowID, String, String, pid_t)] {
        var allWindowsInfo: [(CGWindowID, String, String, pid_t)] = []
        
        // Get ALL windows across ALL spaces
        let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return allWindowsInfo
        }
        
        for windowInfo in windowList {
            print("appname: ")
            print(windowInfo[kCGWindowOwnerName as String])
            // Filter out windows we don't want
            guard let windowLayer = windowInfo[kCGWindowLayer as String] as? Int,
                  windowLayer == 0, // Normal windows only
                  let windowAlpha = windowInfo[kCGWindowAlpha as String] as? Double,
                  windowAlpha > 0, // Visible windows only
                  let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? Double,
                  let height = bounds["Height"] as? Double,
                  width > 50 && height > 50 // Skip tiny windows
            else { continue }
            
            let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID ?? 0
            let windowTitle = windowInfo[kCGWindowName as String] as? String ?? ""
            let appName = windowInfo[kCGWindowOwnerName as String] as? String ?? ""
            let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t ?? 0
            
            if !windowTitle.isEmpty {
                allWindowsInfo.append((windowID, windowTitle, appName, pid))
            }
        }
        
        return allWindowsInfo
    }
    
    private func getWindowSpaceID(window: AXUIElement) -> Int? {
        // This is a simplified approach - getting actual space IDs requires private APIs
        // or more complex CoreGraphics calls. For now, we'll return nil
        // You could potentially use CGWindowListCopyWindowInfo to get more details
        return nil
    }
    
    private func getCurrentSpaceID() -> Int? {
        // Similarly, getting current space ID reliably requires private APIs
        // This is a placeholder
        return nil
    }
    
    func focusWindow(_ windowInfo: WindowInfo) {
        // First activate the app
        windowInfo.app.activate(options: [.activateIgnoringOtherApps])
        
        if let window = windowInfo.windowRef {
            // Check if window is minimized and unminimize it
            var minimizedRef: CFTypeRef?
            let minimizedResult = AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedRef)
            if minimizedResult == .success, let isMinimized = minimizedRef as? Bool, isMinimized {
                AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, false as CFTypeRef)
            }
            
            // Raise the window
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            
            // Try to focus the window
            var focusedRef: CFTypeRef?
            let focusedResult = AXUIElementCopyAttributeValue(window, kAXFocusedAttribute as CFString, &focusedRef)
            if focusedResult == .success {
                AXUIElementSetAttributeValue(window, kAXFocusedAttribute as CFString, true as CFTypeRef)
            }
            
            // If window is on another space, this should trigger a space switch
            // macOS will automatically switch to the space containing the window
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
