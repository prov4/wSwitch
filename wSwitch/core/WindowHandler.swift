//
//  WindowHandler.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Foundation
import AppKit


class WindowHandler {
    
    let apps = NSWorkspace.shared.runningApplications

    
    func getWindowList() -> Dictionary<String, NSRunningApplication> {
        var runningApps: Dictionary<String, NSRunningApplication> = [:]
        
        for a in apps {
            let name = a.localizedName ?? "Undefinded"
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
