//
//  RSTokenCompletionWindowController.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa
import Carbon

class RSTokenCompletionWindowController: NSWindowController, NSWindowDelegate, NSTableViewDelegate, NSTableViewDataSource {

    static let sharedInstance = RSTokenCompletionWindowController()
    
    var completionsArray: [String] = []
    var textView: RSTokenTextView?
    var completionStem = ""
    var rawStem = ""
    var completionIndex: Int = 0
    var completionWindow: NSWindow? = nil
    var tableView: RSTokenCompletionTableView? = nil
    var tokenisingCharacterSet: NSCharacterSet? = nil

    private var eventMonitor: AnyObject? = nil
    
    //MARK: Initalizers
    private init() {
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    //MARK: Setup/Teardown
    func setupWindow() {
        let scrollFrame = NSMakeRect(0, 0, 200, 150)
        var tableFrame = NSZeroRect
        tableFrame.size = NSMakeSize(0, 0)
        
        let completionWindow = NSWindow.init(contentRect: scrollFrame, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, `defer`: false)
        completionWindow.windowController = self
        self.window = completionWindow
        completionWindow.alphaValue = 0.85
        completionWindow.hasShadow = true
        completionWindow.oneShot = true
        completionWindow.releasedWhenClosed = false
        completionWindow.delegate = self
        self.completionWindow = completionWindow
        
        let tableView = RSTokenCompletionTableView(frame:scrollFrame)
        self.tableView = tableView
        tableView.autoresizingMask = .ViewWidthSizable
        
        let column = NSTableColumn.init(identifier: "completions")
        column.width = scrollFrame.size.width
        column.editable = false
        tableView.addTableColumn(column)
        
        tableView.gridStyleMask = .GridNone
        tableView.cornerView = nil
        tableView.headerView = nil
        tableView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
        
        tableView.setDelegate(self)
        tableView.setDataSource(self)
        tableView.action = "tableViewClicked:"
        tableView.target = self
        tableView.doubleAction = "tableAction:"
        tableView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        
        let scrollView = NSScrollView.init(frame: scrollFrame)
        scrollView.borderType = .NoBorder
        scrollView.hasVerticalScroller = true
        scrollView.autoresizingMask = [.ViewWidthSizable, .ViewHeightSizable]
        scrollView.documentView = tableView
        scrollView.autohidesScrollers = true
        
        self.completionWindow?.contentView = scrollView
        self.completionWindow?.level = Int(CGWindowLevelForKey(.PopUpMenuWindowLevelKey))
        
    }

    func tearDownWindow() {
        if let _ = self.eventMonitor {
            NSEvent .removeMonitor(self.eventMonitor!)
        }
        if let _ = self.completionWindow {
            self.textView?.window?.removeChildWindow(self.completionWindow!)
        }
        
        self.completionWindow?.orderOut(false)
        self.completionStem = ""
        self.completionWindow = nil
        self.rawStem = ""
    }
    
    //MARK: Utility Methods
    
    func isDisplayingCompletions() -> Bool {
        if let _ = self.completionWindow {
            return (self.completionWindow?.visible)!
        } else {
            return false
        }
    }
    
    override func insertText(insertString: AnyObject) {
        if let _ = self.completionWindow {
            self.rawStem.appendContentsOf(insertString as! String)
        } else {
            self.rawStem = insertString.mutableCopy() as! String
        }
        return
    }
    
    //MARK: Window Display Methods
    func displayCompletionsForStem(stem: String, forTextView aTextView: RSTokenTextView, forRange stemRange: NSRange) -> Bool {
        self.completionIndex = stemRange.location
        self.completionStem = stem
        self.textView = aTextView
        self.completionsArray = (aTextView.getCompletionsForStem(stem))
        
        if self.completionsArray.count > 0 {
            if let _ = self.completionWindow {
                self.tableView?.reloadData()
                self.tableView?.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
            } else {
                self.setupWindow()
                self.tableView?.reloadData()
                self.tableView?.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
                
                // Completion Window Rectangle
                var rect = aTextView.firstRectForCharacterRange(aTextView.rangeForCompletion(0), actualRange: nil)
                // Push the rectangle down to account for the window inset
                rect.origin.y -= 5
                var screenMaxX: CGFloat = 0.0
                for (_, aScreen) in (NSScreen.screens()?.enumerate())! {
                    if NSPointInRect(rect.origin, aScreen.visibleFrame) {
                        screenMaxX = NSMaxX(aScreen.visibleFrame)
                        break
                    }
                }
                
                rect.origin.x = min(rect.origin.x, screenMaxX - NSWidth(self.completionWindow!.frame))
                self.completionWindow?.setFrameTopLeftPoint(rect.origin)
                
                self.completionWindow?.orderFrontRegardless()
                self.textView?.window?.addChildWindow(self.completionWindow!, ordered: .Above)
                
                self.eventMonitor = NSEvent.addLocalMonitorForEventsMatchingMask([.KeyDownMask, .LeftMouseDownMask, .RightMouseDownMask], handler: {[unowned self] (theEvent: NSEvent) -> NSEvent? in
                    if theEvent.type == .KeyDown {
                        if theEvent.modifierFlags.contains(NSEventModifierFlags.CommandKeyMask) {
                            self.tearDownWindow()
                            return theEvent
                        }
                        
                        let keyCode = Int(theEvent.keyCode)
                        switch keyCode {
                        case kVK_Escape:
                            self.textView?.abandonCompletion()
                            return nil
                        case kVK_Delete:
                            if (self.textView?.hasMarkedText() == true) {
                                self.textView?.unmarkText()
                            }
                            break
                        case kVK_Tab:
                            let selectedRow = self.tableView!.selectedRow
                            assert(selectedRow >= 0 && selectedRow < self.completionsArray.count, "Invalid Selected Row")
                            self.chooseCompletion(self.completionsArray[selectedRow], forTextView: self.textView!)
                            self.tearDownWindow()
                            self.textView?.window?.sendEvent(theEvent)
                            return nil
                        case kVK_Return:
                            let selectedRow = self.tableView!.selectedRow
                            assert(selectedRow >= 0 && selectedRow < self.completionsArray.count, "Invalid Selected Row")
                            self.chooseCompletion(self.completionsArray[selectedRow], forTextView: self.textView!)
                            self.tearDownWindow()
                            return nil
                        case kVK_DownArrow:
                            let selectedRow = self.tableView!.selectedRow
                            if selectedRow < self.tableView!.numberOfRows - 1 {
                                self.tableView?.selectRowIndexes(NSIndexSet(index: selectedRow + 1), byExtendingSelection: false)
                            }
                            return nil
                        case kVK_UpArrow:
                            let selectedRow = self.tableView!.selectedRow
                            if selectedRow > 0 {
                                self.tableView?.selectRowIndexes(NSIndexSet(index: selectedRow - 1), byExtendingSelection: false)
                            }
                            return nil
                        default:
                            break
                        }
                        
                        self.textView?.inputContext?.handleEvent(theEvent)
                        return nil
                    }
                    
                    if theEvent.window == self.completionWindow {
                        return theEvent
                    } else {
                        var range = self.textView!.selectedRange()
                        range.length = (range.location) + range.length - self.completionIndex
                        range.location = self.completionIndex
                        self.textView?.replaceCharactersInRange(range, withString: self.rawStem)
                        
                        self.tearDownWindow()
                        return theEvent
                    }
                })
            }
        } else {
            if let _ = self.completionWindow {
                let r = self.textView?.rangeForCompletion(0)
                self.textView?.replaceCharactersInRange(r!, withString: self.rawStem)
                self.tearDownWindow()
            }
        }
        
        return self.completionWindow != nil
    }
    
    func chooseCompletion(completion: String, forTextView aTextView: RSTokenTextView) {
        aTextView.insertTokenForText(completion, replacementRange: aTextView.rangeForCompletion(completion.characters.count))
    }
    
    // MARK: TableView Delegate Methods
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.completionsArray.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let stringToDisplay = self.completionsArray[row]
        return stringToDisplay
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        if self.isDisplayingCompletions() {
            let selectedRow = self.tableView?.selectedRow
            if selectedRow >= 0 && selectedRow < self.completionsArray.count {
                
            } else {
                self.tearDownWindow()
            }
        }
    }
    
    func tableViewClicked(sender: AnyObject) {
        let selectedRow = self.tableView?.selectedRow
        if selectedRow >= 0 && selectedRow < self.completionsArray.count {
            self.chooseCompletion(self.completionsArray[selectedRow!], forTextView: self.textView!)
        }
        self.tearDownWindow()
    }
    
    func tableAction(sender: AnyObject) {
        
    }
}
