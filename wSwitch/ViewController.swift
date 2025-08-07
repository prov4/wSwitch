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
        view.window?.isOpaque = false
        view.window?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.8)
        
        // Refresh window list when view appears
        refreshWindowList()
        
        // Focus search field
        view.window?.makeFirstResponder(searchField)
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
            
            // Hide the app after switching
            NSRunningApplication.current.hide()
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
                NSRunningApplication.current.hide()
            }
            return true
        } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // Escape key pressed - hide the app
            NSRunningApplication.current.hide()
            return true
        }
        
        return false
    }
}
