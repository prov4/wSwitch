//
//  ViewController.swift
//  wSwitch
//
//  Created by Josip Povreslo on 25.09.2023..
//

import Cocoa

class ViewController: NSViewController, NSSearchFieldDelegate {
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var windowList: NSScrollView!
    var windowHandler = WindowHandler()
    var allWindows: [WindowInfo] = []
    var filteredWindows: [WindowInfo] = []
    @IBOutlet weak var tableView: NSTableView!
    var tableCell: NSTableCellView!
    @IBOutlet weak var stackView: NSStackView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchField.delegate = self
        refreshWindowList()
        
        // Make search field first responder
        view.window?.makeFirstResponder(searchField)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // Configure window appearance
        if let window = view.window {
            window.isOpaque = false
            window.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.95)
            window.hasShadow = true
            
            // Force window to front
            window.orderFrontRegardless()
            window.makeKeyAndOrderFront(nil)
            
            // Ensure the window is active
            NSApp.activate(ignoringOtherApps: true)
        }
        
        // Clear search field when window appears
        searchField.stringValue = ""
        
        // Refresh window list when view appears
        refreshWindowList()
        
        // Focus search field immediately and after a brief delay
        view.window?.makeFirstResponder(searchField)
        searchField.becomeFirstResponder()
        
        // Double-ensure focus after window is fully shown
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            self.view.window?.makeFirstResponder(self.searchField)
            self.searchField.selectText(nil)
        }
    }
    
    func refreshWindowList() {
        // Get all windows
        self.allWindows = windowHandler.getAllWindows()
        
        // Start with all windows visible
        self.filteredWindows = self.allWindows
        
        // Display all windows
        updateStackView()
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @objc func windowButtonClick(_ sender: NSButton) {
        print("Window clicked: \(sender.title)")
        
        // Find the window info by button tag
        let index = sender.tag
        if index >= 0 && index < filteredWindows.count {
            let windowInfo = filteredWindows[index]
            windowHandler.focusWindow(windowInfo)
            
            // Hide the app window and return to tray
            hideAppWindow()
        }
    }
    
    func controlTextDidChange(_ obj: Notification) {
        let textField = obj.object as! NSTextField
        let searchText = textField.stringValue
        print("Search text: \(searchText)")
        
        filterWindows(searchText: searchText)
    }
    
    func filterWindows(searchText: String) {
        if searchText.isEmpty {
            // Show all windows if search is empty
            filteredWindows = allWindows
        } else {
            // Filter windows based on search text
            filteredWindows = allWindows.filter { windowInfo in
                windowInfo.title.lowercased().contains(searchText.lowercased())
            }
        }
        
        updateStackView()
    }
    
    func updateStackView() {
        // Clear existing views
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        
        // Add filtered windows
        for (index, windowInfo) in filteredWindows.enumerated() {
            let button = createWindowButton(windowInfo: windowInfo, index: index)
            stackView.addArrangedSubview(button)
        }
    }
    
    func createWindowButton(windowInfo: WindowInfo, index: Int) -> NSButton {
        let button = NSButton(title: windowInfo.title,
                             image: windowInfo.app.icon ?? NSImage(),
                             target: self,
                             action: #selector(windowButtonClick))
        button.tag = index
        button.imagePosition = .imageLeft
        button.alignment = .left
        button.isBordered = false
        button.bezelStyle = .regularSquare
        
        // Style the button
        if let cell = button.cell as? NSButtonCell {
            cell.highlightsBy = .changeBackgroundCellMask
        }
        
        return button
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            // Enter key pressed - activate first window in filtered list
            if !filteredWindows.isEmpty {
                let firstWindow = filteredWindows[0]
                windowHandler.focusWindow(firstWindow)
                hideAppWindow()
            }
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape key pressed - hide the app window
            hideAppWindow()
            return true
        }
        
        return false
    }
    
    private func hideAppWindow() {
        // Hide window and return to tray
        view.window?.close()
        
        // Return to accessory mode (hide from dock)
        NSApp.setActivationPolicy(.accessory)
    }
}
