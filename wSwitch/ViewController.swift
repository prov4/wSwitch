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
    var stackView: NSStackView!
    var allWindows: Dictionary<String, NSRunningApplication> = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchField.delegate = self
        self.allWindows = windowHandler.getWindowList()
        
//        self.searchTxtField.delegate = self
                
        stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .centerX
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false

        windowList.documentView = stackView

        filterAndSetupAppList(name: "")
        
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.isOpaque = false
        view.window?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 0.8)
    }
    

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc func appClick(_ sender: NSButton){
        print("App is clicked: \(sender.title)")
        self.allWindows[sender.title]?.activate()
    }

    func controlTextDidChange(_ obj: Notification){
        let textField = obj.object as! NSTextField
        let text = textField.stringValue
        print("Change: \(text)")
        filterAndSetupAppList(name: text)
    }
    
    func filterAndSetupAppList(name: String) {
        if name.count > 0 {
            for item in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(item)
                item.removeFromSuperview()
            }
        }

        for (key, value) in self.allWindows {
            if key.contains(name) && !key.contains("("){
                addButtonToStackView(stackView: stackView, title: key, icon: value.icon!)
                
            } 
        }
    }
    
    func addButtonToStackView( stackView: NSStackView, title: String, icon: NSImage ) {
        let appButton = NSButton(title: title, image: icon, target: self, action: #selector(appClick))
        stackView.addArrangedSubview(appButton)
    }
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            // Do something against ENTER key
            if let stackView = stackView, let firstButton = stackView.arrangedSubviews[0] as? NSButton {
                // Use 'firstButton' safely as NSButton
                print(firstButton.title)
                self.allWindows[firstButton.title]?.activate()
            }
            print("enter")
            NSRunningApplication.current.hide()
            
            return true
        }
//            else if (commandSelector == #selector(NSResponder.deleteForward(_:))) {
//            // Do something against DELETE key
//            return true
//        } else if (commandSelector == #selector(NSResponder.deleteBackward(_:))) {
//            // Do something against BACKSPACE key
//            return true
//        } else if (commandSelector == #selector(NSResponder.insertTab(_:))) {
//            // Do something against TAB key
//            return true
//        } else if (commandSelector == #selector(NSResponder.cancelOperation(_:))) {
//            // Do something against ESCAPE key
//            return true
//        }
        
        // return true if the action was handled; otherwise false
        return false
    }
    

}

