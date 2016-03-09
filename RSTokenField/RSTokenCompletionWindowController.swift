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
    
    var completionsArray: [RSTokenItemType] = []
    var textView: RSTokenTextView?
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
        let scrollFrame = NSMakeRect(0, 0, (self.textView?.frame.width)!, 150)
        
        let completionWindow = NSWindow.init(contentRect: scrollFrame, styleMask: NSBorderlessWindowMask, backing: NSBackingStoreType.Buffered, `defer`: false)
        completionWindow.windowController = self
        self.window = completionWindow
        completionWindow.alphaValue = 1.0
        completionWindow.hasShadow = true
        completionWindow.oneShot = true
        completionWindow.releasedWhenClosed = false
        completionWindow.delegate = self
        self.completionWindow = completionWindow
        
        let tableView = RSTokenCompletionTableView(frame:scrollFrame)
        self.tableView = tableView
        
        let column = NSTableColumn.init(identifier: "completions")
        column.width = scrollFrame.size.width
        column.editable = false
        tableView.addTableColumn(column)
        
        tableView.gridStyleMask = .GridNone
        tableView.cornerView = nil
        tableView.headerView = nil
        tableView.columnAutoresizingStyle = .UniformColumnAutoresizingStyle
        tableView.selectionHighlightStyle = .SourceList
        tableView.rowSizeStyle = .Custom
        
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
            NSEvent.removeMonitor(self.eventMonitor!)
        }
        if let _ = self.completionWindow {
            self.textView?.window?.removeChildWindow(self.completionWindow!)
        }
        
        self.completionWindow?.orderOut(false)
        self.completionWindow = nil
        self.rawStem = ""
    }
    
    func setupEventMonitor() {
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
                    self.chooseCompletion((self.completionsArray[selectedRow] as! RSTokenItem).tokenTitle, forTextView: self.textView!)
                    self.tearDownWindow()
                    self.textView?.window?.sendEvent(theEvent)
                    return nil
                case kVK_Return:
                    let selectedRow = self.tableView!.selectedRow
                    assert(selectedRow >= 0 && selectedRow < self.completionsArray.count, "Invalid Selected Row")
                    self.chooseCompletion((self.completionsArray[selectedRow] as! RSTokenItem).tokenTitle, forTextView: self.textView!)
                    self.tearDownWindow()
                    return nil
                case kVK_DownArrow:
                    var selectedRow = self.tableView!.selectedRow
                    if selectedRow < self.tableView!.numberOfRows - 1 {
                        selectedRow++
                        if self.completionsArray[selectedRow] is RSTokenItemSection {
                            selectedRow++
                        }
                        self.tableView?.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
                    }
                    return nil
                case kVK_UpArrow:
                    var selectedRow = self.tableView!.selectedRow
                    if selectedRow > 1 {
                        selectedRow--
                        if self.completionsArray[selectedRow] is RSTokenItemSection {
                            selectedRow--
                        }
                        self.tableView?.selectRowIndexes(NSIndexSet(index: selectedRow), byExtendingSelection: false)
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
        self.textView = aTextView
        self.completionsArray = (aTextView.getCompletionsForStem(stem))
    
        if self.completionsArray.count > 0 {
            if let _ = self.completionWindow {
                self.tableView?.reloadData()
                self.tableView?.selectRowIndexes(NSIndexSet(index: 1), byExtendingSelection: false)
            } else {
                self.setupWindow()
                self.setupEventMonitor()
                
                self.tableView?.reloadData()
                self.tableView?.selectRowIndexes(NSIndexSet(index: 1), byExtendingSelection: false)
                
                // Completion Window Rectangle
                var rect = aTextView.firstRectForCharacterRange(aTextView.rangeForCompletion(), actualRange: nil)
                // Push the rectangle down to account for the window inset
                rect.origin.y -= 10
                var screenMaxX: CGFloat = 0.0
                
                NSScreen.screens()?.forEach({ (aScreen: NSScreen) -> () in
                    if NSPointInRect(rect.origin, aScreen.visibleFrame) {
                        screenMaxX = NSMaxX(aScreen.visibleFrame)
                    }
                })
                
                rect.origin.x = min(rect.origin.x, screenMaxX - NSWidth(self.completionWindow!.frame))
                self.completionWindow?.setFrameTopLeftPoint(rect.origin)
                
                self.completionWindow?.orderFrontRegardless()
                self.textView?.window?.addChildWindow(self.completionWindow!, ordered: .Above)
                
            }
        } else {
            if let _ = self.completionWindow {
                _ = self.textView?.rangeForCompletion()
                //self.textView?.replaceCharactersInRange(r!, withString: self.rawStem)
                self.tearDownWindow()
            }
        }
        
        return self.completionWindow != nil
    }
    
    func chooseCompletion(completion: String, forTextView aTextView: RSTokenTextView) {
        aTextView.insertTokenForText(completion, replacementRange: aTextView.rangeForCompletion())
    }
    
    // MARK: TableView Delegate Methods
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return self.completionsArray.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tokenItemType = self.completionsArray[row]
        
        if tokenItemType is RSTokenItemSection {
            var sectionHeader = tableView.makeViewWithIdentifier("RSTokenItemSection", owner: self) as? RSTableCellView
            
            
            
            if sectionHeader == nil {
                var topLevelObjects: NSArray?
                NSBundle.mainBundle().loadNibNamed("RSTableCellView",
                    owner:self, topLevelObjects:&topLevelObjects)
                
                for o in topLevelObjects! {
                    if o is RSTableCellView {
                        sectionHeader = o as? RSTableCellView
                    }
                }
                
                sectionHeader?.frame = NSMakeRect(0, 0, tableView.frame.size.width, tableView.frame.size.height)
                sectionHeader!.identifier = "RSTokenItemSection"
            }
            
            sectionHeader?.textField!.bezeled = false
            sectionHeader?.textField!.stringValue = (tokenItemType as! RSTokenItemSection).sectionName
            
            return sectionHeader
        } else if tokenItemType is RSTokenItem {
            var tokenItem = tableView.makeViewWithIdentifier("RSTokenItem", owner: self) as? RSTableCellView
            if tokenItem == nil {
                var topLevelObjects: NSArray?
                NSBundle.mainBundle().loadNibNamed("RSTableCellView",
                    owner:self, topLevelObjects:&topLevelObjects)
                
                for o in topLevelObjects! {
                    if o is RSTableCellView {
                        tokenItem = o as? RSTableCellView
                    }
                }
                
                tokenItem?.frame = NSMakeRect(0, 0, tableView.frame.size.width, tableView.frame.size.height)
                tokenItem!.identifier = "RSTokenItem"
            }
            
            tokenItem?.textField!.bezeled = false
            tokenItem?.textField!.drawsBackground = false
            tokenItem?.textField!.stringValue = (tokenItemType as! RSTokenItem).tokenTitle
            
            return tokenItem
        }
        
        return nil
    }
    
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        let tokenItemType = self.completionsArray[row]
        
        if tokenItemType is RSTokenItemSection {
            return 25
        } else {
            return 25
        }
    }
    
    func tableView(tableView: NSTableView, isGroupRow row: Int) -> Bool {
        let tokenItemType = self.completionsArray[row]
        if tokenItemType is RSTokenItemSection {
            return true
        } else {
            return false
        }
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        let tokenItemType = self.completionsArray[row]
        if tokenItemType is RSTokenItemSection {
            return false
        } else {
            return true
        }
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
            self.chooseCompletion((self.completionsArray[selectedRow!] as! RSTokenItem).tokenTitle, forTextView: self.textView!)
        }
        self.tearDownWindow()
    }
    
    func tableAction(sender: AnyObject) {
        
    }
}
