//
//  RSTokenTextView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTokenTextView: NSTextView {

    //MARK: Private Properties
    private struct RSTokenPosition {
        enum Direction {
            case Left
            case Right
            case None
        }
        
        var direction: Direction = .None
        var selected: Bool = false
        var oldRange: NSRange = NSMakeRange(NSNotFound, NSNotFound)
        var newRange: NSRange = NSMakeRange(NSNotFound, NSNotFound)
    }
    
    private var lastSelectedTokenPosition = RSTokenPosition()
    private var mouseWasDragged: Bool = false {
        willSet {
            if newValue == false {
                self.insertionPointColor = NSColor.blackColor()
                self.typingAttributes = [NSFontAttributeName:NSFont.systemFontOfSize(12)]
                self.textStorage?.removeAttribute(NSBackgroundColorAttributeName, range: NSMakeRange(0, (self.textStorage?.length)!))
                self.lastSelectedTokenPosition = RSTokenPosition()
            }
        }
    }
    
    private var lastEnteredStem: String = ""
    private var copiedString: NSMutableAttributedString? = nil
    private var didRedoDelete: Bool = false
    
    //MARK: Overrides
    override func resignFirstResponder() -> Bool {
        self.tokenizeRemainingText()
        return false
    }
    
    override func completionsForPartialWordRange(charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String]? {
        return nil
    }
    
    override func writeSelectionToPasteboard(pboard: NSPasteboard, type: String) -> Bool {
        return true
    }
    
    override func readSelectionFromPasteboard(pboard: NSPasteboard) -> Bool {
        return true
    }
    
    override func performKeyEquivalent(theEvent: NSEvent) -> Bool {
        let commandKey = NSEventModifierFlags.CommandKeyMask.rawValue
        let commandShiftKey = NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.ShiftKeyMask.rawValue
        
        if theEvent.type == NSEventType.KeyDown {
            if (theEvent.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandKey {
                switch theEvent.charactersIgnoringModifiers! {
                case "x":
                    if NSApp.sendAction(Selector("cut:"), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(Selector("copy:"), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(Selector("paste:"), to:nil, from:self) { return true }
                case "z":
                    if NSApp.sendAction(Selector("undo:"), to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(Selector("selectAll:"), to:nil, from:self) { return true }
                default:
                    break
                }
            } else if (theEvent.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandShiftKey {
                if theEvent.charactersIgnoringModifiers == "Z" {
                    if NSApp.sendAction(Selector("redo:"), to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(theEvent)
    }
    
    //MARK: Text Insertion Methods
    func insertTokenForText(tokenText: String, replacementRange: NSRange) {
        self.undoManager?.beginUndoGrouping()
        
        let delegate = self.delegate as! RSTokenField
        if delegate.shouldAddToken(tokenText, atTokenIndex: self.countOfTokensInRange(NSMakeRange(0, replacementRange.location))) {
            // Used for replacing the token on double click
            self.lastEnteredStem = RSTokenCompletionWindowController.sharedInstance.rawStem
            let insertiontext = self.tokenForString(tokenText)
            
            let delegate = self.delegate as! RSTokenField
            //Disabling undo registration because, super call will club this insertion with the regular text insertion
            self.undoManager?.disableUndoRegistration()
            super.insertText(insertiontext, replacementRange: replacementRange)
            self.undoManager?.enableUndoRegistration()
            delegate.textView(self, didChangeTokens: self.tokenArray())
            
            self.undoManager?.registerUndoWithTarget(self, handler: {[range = replacementRange] (RSTokenTextView) -> () in
                self.replaceCharactersInRange(range, withString: "")
            })
            self.undoManager?.setActionName("Undo-Tokenizer")
            self.setSelectedRange(NSMakeRange(NSMaxRange(replacementRange), 0))
        }
        
        self.undoManager?.endUndoGrouping()
        self.dumpUndoStack()
    }
    
    override func replaceCharactersInRange(range: NSRange, withString aString: String) {
        if self.shouldChangeTextInRange(range, replacementString: aString) {
            super.replaceCharactersInRange(range, withString: aString)
        }
    }
    
    override func insertText(aString: AnyObject, replacementRange: NSRange) {
        guard let textStorage = self.textStorage else { return }
        //self.undoManager?.beginUndoGrouping()
        // Erase all the selection and reset the attributes for textStorage and typing
        if self.mouseWasDragged {
            let deleteRange = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
            if NSMaxRange(deleteRange) <= self.textStorage?.length {
                self.setSelectedRange(deleteRange)
                self.delete(nil)
            }
            self.mouseWasDragged = false
        }
        
        let insertionIndex = self.selectedRange().location
        // Delete Tokens that are selected and insert text in their position
        if insertionIndex < textStorage.length && textStorage.isTokenAtIndexSelected(insertionIndex + 1) {
            textStorage.deleteCharactersInRange(NSMakeRange(insertionIndex, 3))
        } else if insertionIndex > 2 && textStorage.isTokenAtIndexSelected(insertionIndex - 2) {
            textStorage.deleteCharactersInRange(NSMakeRange(insertionIndex - 3, 3))
        }
        
        if insertionIndex != NSNotFound {
            let completionController = RSTokenCompletionWindowController.sharedInstance
            
            if completionController.isDisplayingCompletions() {
                completionController.insertText(aString)
            } else {
                let startingStemRange = self.rangeForCompletion()
                let selectionIndex = self.selectedRange().location - startingStemRange.location
                let replacedText = (textStorage.string as NSString).substringWithRange(startingStemRange)
                
                let startingStem = NSMutableString(string: replacedText)
                startingStem.insertString(aString as! String, atIndex: selectionIndex)
                
                completionController.insertText(startingStem)
            }
            
            
            if insertionIndex <= textStorage.length {
                let stemRange = self.completionRange()
                
                completionController.displayCompletionsForStem(completionController.rawStem, forTextView: self, forRange: stemRange)
            }
        }
        
        // Whenever a character is entered mark all token as unselected
        self.insertionPointColor = NSColor.blackColor()
        (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: selectedRange.location)
        self.setSelectedRange(NSMakeRange(insertionIndex, 0))
        
        super.insertText(aString, replacementRange: replacementRange)
        //self.undoManager?.endUndoGrouping()
    }
    
    override func doCommandBySelector(aSelector: Selector) {
        let completionController = RSTokenCompletionWindowController.sharedInstance
        guard let textStorage = self.textStorage else { return }

        if aSelector == "insertNewline:" {
            return
        } else if aSelector == "moveToLeftEndOfLine:" {
            (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: 0)
            self.mouseWasDragged = false
            self.setSelectedRange(NSMakeRange(0, 0))
        } else if aSelector == "moveToRightEndOfLine:" {
            (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: 0)
            self.mouseWasDragged = false
            self.setSelectedRange(NSMakeRange(textStorage.length, 0))
        } else if aSelector == "deleteBackward:" {
            if self.mouseWasDragged {
                let deleteRange = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
                //Delete
                self.setSelectedRange(deleteRange)
                self.delete(nil)
                self.mouseWasDragged = false
            } else if self.selectedRange.location >= 0 {
                
                let tokenIndex = self.selectedRange().location - 2
                
                if self.selectedRange().location < textStorage.length && textStorage.isTokenAtIndexSelected(self.selectedRange().location + 1) {
                    //The token is already selected and ready to be deleted at this point
                    self.setSelectedRange(NSMakeRange(self.selectedRange().location, 3))
                    self.delete(nil)
                    self.insertionPointColor = NSColor.blackColor()
                } else if tokenIndex > 0 && textStorage.tokenStringAtIndex(tokenIndex) != nil {
                    if textStorage.isTokenAtIndexSelected(tokenIndex) {
                        //The token is already selected and ready to be deleted at this point
                        self.setSelectedRange(NSMakeRange(tokenIndex - 1, 3))
                        self.delete(nil)
                        self.insertionPointColor = NSColor.blackColor()
                    } else {
                        //This is a token, highlight this but do not delete it
                        (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: tokenIndex)
                        self.insertionPointColor = NSColor.whiteColor()
                    }
                    //Offset the text cursor position by token position - 1 (whitespace)
                    self.setSelectedRange(NSMakeRange(tokenIndex - 1, 0))
                    
                } else {
                    //delete the character
                    super.deleteBackward(self)
                    //Abandon any token completion
                    if completionController.isDisplayingCompletions() {
                        completionController.tearDownWindow()
                    }
                    self.insertionPointColor = NSColor.blackColor()
                }
            }
            
            return
        } else if aSelector == "moveLeft:" {
            if self.mouseWasDragged {
                (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: 0)
                
                var insertionIndex = 0
                
                if self.lastSelectedTokenPosition.newRange.length != textStorage.length {
                    if self.lastSelectedTokenPosition.direction == .Right {
                        insertionIndex = self.lastSelectedTokenPosition.oldRange.location
                    } else {
                        insertionIndex = self.lastSelectedTokenPosition.newRange.location
                    }
                }
                
                if (textStorage.tokenStringAtIndex(insertionIndex)) != nil {
                    self.setSelectedRange(NSMakeRange(insertionIndex - 1, 0))
                } else {
                    self.setSelectedRange(NSMakeRange(insertionIndex, 0))
                }
                
                self.mouseWasDragged = false
                return
            }
            
            self.lastSelectedTokenPosition = RSTokenPosition()
            self.abandonCompletion()
            let selectedRange = self.selectedRange()
            if selectedRange.location >= 0 && (selectedRange.location + selectedRange.length) <= self.textStorage?.length {
                let selectedIndex = selectedRange.location - 2
                if self.insertionPointColor == NSColor.whiteColor() {
                    let nearestSelectedRange = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(selectedRange.location - 2, 0))
                    (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: selectedRange.location + 2)
                    self.insertionPointColor = NSColor.blackColor()
                    if nearestSelectedRange.location == NSNotFound {
                        self.setSelectedRange(NSMakeRange(selectedRange.location, 0))
                    } else {
                        self.setSelectedRange(NSMakeRange(nearestSelectedRange.location - 1, 0))
                    }
                    return
                } else if (selectedIndex >= 0 && (self.textStorage?.tokenStringAtIndex(selectedIndex)) != nil) {
                    if !self.lastSelectedTokenPosition.selected {
                        self.lastSelectedTokenPosition.selected = true
                        self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
                        self.lastSelectedTokenPosition.direction = .Left
                    }
                    
                    (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: selectedIndex)
                    self.setSelectedRange(NSMakeRange(selectedIndex - 1, 0))
                    self.insertionPointColor = NSColor.whiteColor()
                    self.lastSelectedTokenPosition.newRange = self.selectedRange()
                    return
                } else {
                    self.insertionPointColor = NSColor.blackColor()
                }
            }
        } else if aSelector == "moveRight:" {
            if self.mouseWasDragged {
                (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: 0)
                
                var insertionIndex = 0
                if self.lastSelectedTokenPosition.newRange.length != textStorage.length {
                    insertionIndex = max(self.lastSelectedTokenPosition.newRange.location + self.lastSelectedTokenPosition.newRange.length,
                                        self.lastSelectedTokenPosition.oldRange.location + self.lastSelectedTokenPosition.oldRange.length)
                } else {
                    insertionIndex = textStorage.length
                }
                
                if textStorage.tokenStringAtIndex(insertionIndex) != nil {
                    self.setSelectedRange(NSMakeRange(insertionIndex + 2, 0))
                } else {
                    self.setSelectedRange(NSMakeRange(insertionIndex, 0))
                }

                self.mouseWasDragged = false
                return
            } else {
                self.lastSelectedTokenPosition = RSTokenPosition()
                self.abandonCompletion()
                
                let selectedRange = self.selectedRange()
                if selectedRange.location >= 0 && selectedRange.location <= self.textStorage?.length {
                    let selectedIndex = selectedRange.location + 1
                    if self.insertionPointColor == NSColor.whiteColor() {
                        let nearestSelectedRange = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(selectedRange.location + 1, 0))
                        (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: selectedRange.location - 1)
                        self.insertionPointColor = NSColor.blackColor()
                        if nearestSelectedRange.location == NSNotFound {
                            self.setSelectedRange(NSMakeRange(selectedRange.location, 0))
                        } else {
                            self.setSelectedRange(NSMakeRange(nearestSelectedRange.location + 2, 0))
                        }
                        return
                    } else if (textStorage.tokenStringAtIndex(selectedIndex) != nil) {
                        if !self.lastSelectedTokenPosition.selected {
                            self.lastSelectedTokenPosition.selected = true
                            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
                            self.lastSelectedTokenPosition.direction = .Right
                        }
                        
                        (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: selectedIndex)
                        self.setSelectedRange(NSMakeRange(selectedIndex + 2, 0))
                        self.insertionPointColor = NSColor.whiteColor()
                        self.lastSelectedTokenPosition.newRange = self.selectedRange()
                        return
                    } else {
                        self.insertionPointColor = NSColor.blackColor()
                    }
                }
            }
        }
        super.doCommandBySelector(aSelector)
    }
    
    
}


//MARK: TOKEN HELPER METHODS
extension RSTokenTextView {
    
    //MARK: Token Methods
    func tokenForString(aString: String) -> NSAttributedString {
        var topLevelObjects: NSArray?
        NSBundle.mainBundle().loadNibNamed("RSTokenView",
            owner:self, topLevelObjects:&topLevelObjects)
        
        var view: RSTokenView!
        
        for o in topLevelObjects! {
            if o is RSTokenView {
                view = o as! RSTokenView
                view!.tokenItem = RSTokenItem.init(type: "Kind", title: aString)
                view!.tokenItem.stem = self.lastEnteredStem
            }
        }
        
        let appendedAttributeString = NSMutableAttributedString()
        let attachment = RSTextAttachment.init(withTokenView: view)
        let whiteSpace = NSMutableAttributedString(string: " ")
        
        let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
        attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
        
        appendedAttributeString.appendAttributedString(whiteSpace)
        appendedAttributeString.appendAttributedString(attributeString)
        appendedAttributeString.appendAttributedString(whiteSpace)
        
        return appendedAttributeString
    }
    
    // Used to delete Tokens
    func countOfTokensInRange(aRange: NSRange) -> Int {
        return (self.textStorage?.countOfRSTokensInRange(aRange))!
    }
    
    
    func tokenArray() -> [RSTokenItemType] {
        
        var tokenArray = [RSTokenItemType]()
        guard let textStorage = self.textStorage else { return tokenArray }
        
        let textStorageLength = textStorage.length
        if textStorageLength > 0 {
            var curRange = NSMakeRange(textStorageLength - 1, 0)
            while curRange.location != NSNotFound {
                if let attribute = textStorage.attribute(NSAttachmentAttributeName, atIndex: curRange.location, effectiveRange: &curRange) where attribute is RSTextAttachment {
                    tokenArray.append((attribute as! RSTextAttachment).tokenView.tokenItem)
                } else if let string: NSAttributedString = textStorage.attributedSubstringFromRange(curRange) {
                    tokenArray.append(RSTokenItemSection.init(name: string.string))
                }
                
                curRange = NSMakeRange(curRange.location > 0 ? curRange.location - 1 : NSNotFound, 0)
            }
        }
        return tokenArray
    }
    
    func tokenizeRemainingText() {
        if let delegate = self.delegate as? RSTokenField {
            delegate.textView(self, didChangeTokens: self.tokenArray())
        }
    }
    
    // Used to Insert Tokens
    func rangeForCompletion() -> NSRange {
        let effectiveRange = self.selectedRange()
        var startLocation = self.selectedRange().location
        var endLocation = effectiveRange.location
        guard let curString = self.textStorage else { return NSRange(location: 0, length: 0) }
        
        while startLocation > 2 {
            if curString.isWhiteSpace(startLocation - 1) && curString.tokenStringAtIndex(startLocation - 2) != nil {
                break
            } else {
                startLocation--
            }
        }
        
        while endLocation < (curString.length) - 1 {
            if curString.isWhiteSpace(endLocation) && curString.tokenStringAtIndex(endLocation + 1) != nil {
                break
            } else {
                endLocation++
            }
        }

        return NSMakeRange(startLocation,endLocation-startLocation)
    }
    
    func completionRange() -> NSRange {
        var effectiveRange = self.selectedRange()
        while effectiveRange.location != NSNotFound && effectiveRange.location > 0 {
            let attr = self.textStorage?.attributesAtIndex(effectiveRange.location - 1, effectiveRange: &effectiveRange)
            if (attr![NSAttachmentAttributeName] != nil) {
                effectiveRange.location += effectiveRange.length
                break
            }
        }
        if effectiveRange.location == NSNotFound {
            effectiveRange.location == 0
        }
        effectiveRange.length = self.selectedRange().location - effectiveRange.location
        if self.hasMarkedText() {
            let markedRange = self.markedRange()
            if markedRange.location != NSNotFound {
                effectiveRange.length = markedRange.location - effectiveRange.location
            }
        }
        return effectiveRange
    }
    
    func getCompletionsForStem(stem: String) -> [RSTokenItemType] {
        let delegate = self.delegate as! RSTokenField
        let tokenFieldDelegate = delegate.delegate as! RSTokenFieldDelegate
        return tokenFieldDelegate.tokenField(delegate, completionsForSubstring: stem)
    }
    
    func abandonCompletion() {
        let completionHandler = RSTokenCompletionWindowController.sharedInstance
        if completionHandler.completionWindow != nil {
            let deleteRange = self.rangeForCompletion()
            self.textStorage?.replaceCharactersInRange(deleteRange, withString: completionHandler.rawStem)
            let attributesRange = self.rangeForCompletion()
            self.setSelectedRange(NSMakeRange(min((self.textStorage?.length)!,attributesRange.location + attributesRange.length - 1), 0))
            completionHandler.tearDownWindow()
        }
        
    }
    
    
}

//MARK: KEYBOARD CONTROL OVERRIDES
extension RSTokenTextView {
    override func selectAll(sender: AnyObject?) {
        super.selectAll(sender)
        self.insertionPointColor = NSColor.whiteColor()
        
        self.setTokenStatus(true, startIndex: 0, endIndex: NSMaxRange(self.selectedRange()))
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(0, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = self.selectedRange()
        self.lastSelectedTokenPosition.direction = .Right
        
        self.mouseWasDragged = true
        self.setSelectedRange(NSMakeRange(NSMaxRange(self.selectedRange()), 0))
    }
    
    override func moveWordLeft(sender: AnyObject?) {
        super.moveWordLeft(sender)
        guard let textStorage = self.textStorage else { return }
        
        self.insertionPointColor = NSColor.blackColor()
        var index = self.selectedRange().location
        
        if textStorage.tokenStringAtIndex(index) != nil {
            index--
        }
        
        //If there is a selection present, we look at the following flags to determine the start and end Index
        if self.mouseWasDragged && self.lastSelectedTokenPosition.selected {
            let union = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
            self.setTokenStatus(false, startIndex: union.location, endIndex: NSMaxRange(union))
            if self.lastSelectedTokenPosition.direction == .Right {
                index = union.location
            }
        } else {
            self.setTokenStatus(false, startIndex: index, endIndex: textStorage.length)
        }
        
        self.setSelectedRange(NSMakeRange(index, 0))
        self.mouseWasDragged = false
    }
    
    override func moveWordRight(sender: AnyObject?) {
        super.moveWordRight(sender)
        guard let textStorage = self.textStorage else { return }
        
        self.insertionPointColor = NSColor.blackColor()
        var index = self.selectedRange().location
        
        if textStorage.tokenStringAtIndex(index - 1) != nil {
            index++
        }
        
        //If there is a selection present, we look at the following flags to determine the start and end Index
        if self.mouseWasDragged && self.lastSelectedTokenPosition.selected {
            let union = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
            self.setTokenStatus(false, startIndex: union.location, endIndex: NSMaxRange(union))
            if self.lastSelectedTokenPosition.direction == .Left {
                index = NSMaxRange(union)
            }
        } else {
            self.setTokenStatus(false, startIndex: 0, endIndex: index)
        }
        
        self.setSelectedRange(NSMakeRange(index, 0))
        self.mouseWasDragged = false
    }
    
    override func moveToLeftEndOfLineAndModifySelection(sender: AnyObject?) {
        super.moveToLeftEndOfLineAndModifySelection(sender)
        self.insertionPointColor = NSColor.whiteColor()
        
        self.setTokenStatus(true, startIndex: 0, endIndex: NSMaxRange(self.selectedRange()))
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(0, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = self.selectedRange()
        self.lastSelectedTokenPosition.direction = .Left
        
        self.mouseWasDragged = true
        self.setSelectedRange(NSMakeRange(NSMaxRange(self.selectedRange()), 0))
    }
    
    override func moveToRightEndOfLineAndModifySelection(sender: AnyObject?) {
        super.moveToRightEndOfLineAndModifySelection(sender)
        self.insertionPointColor = NSColor.whiteColor()
        
        self.setTokenStatus(true, startIndex: self.selectedRange().location, endIndex: NSMaxRange(self.selectedRange()))
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = self.selectedRange()
        self.lastSelectedTokenPosition.direction = .Right
        
        self.mouseWasDragged = true
        self.setSelectedRange(NSMakeRange(NSMaxRange(self.selectedRange()), 0))
    }
    
    override func moveWordLeftAndModifySelection(sender: AnyObject?) {
        super.moveWordLeftAndModifySelection(sender)
        guard let textStorage = self.textStorage else { return }
        
        var index = self.selectedRange().location
        
        if self.lastSelectedTokenPosition.selected && self.lastSelectedTokenPosition.direction == .None {
            //NOTE: This is a special case Mouse Double Click text Selection handling
            index = self.lastSelectedTokenPosition.oldRange.location
            //Continuously update the new range (disregard the length, just like in drag)
            self.lastSelectedTokenPosition.oldRange = self.lastSelectedTokenPosition.newRange
            self.lastSelectedTokenPosition.newRange = NSMakeRange(index, 0)
            self.lastSelectedTokenPosition.direction = .Left
            
            //Update the selected Range and modify the selection again by moving the work
            self.setSelectedRange(NSMakeRange(index, 0))
            self.moveWordLeftAndModifySelection(self)
            
            return
        } else if textStorage.tokenStringAtIndex(index) != nil {
            let area = NSMakeRange(index, 2)
            textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
            
            if textStorage.isTokenAtIndexSelected(index) && self.lastSelectedTokenPosition.selected {
                self.lastSelectedTokenPosition.oldRange = NSMakeRange(index - 1, 0)
            }
            index--
        }
        
        let selected = self.lastSelectedTokenPosition.selected && self.lastSelectedTokenPosition.oldRange.location <= index && self.lastSelectedTokenPosition.direction != .None ? false : true
        self.setTokenStatus(selected, startIndex: index, endIndex: index + self.selectedRange().length)
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(NSMaxRange(self.selectedRange()), 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(index, 0)
        self.lastSelectedTokenPosition.direction = .Left
        
        self.setSelectedRange(NSMakeRange(index, 0))
        self.insertionPointColor = index != self.lastSelectedTokenPosition.oldRange.location ? NSColor.whiteColor() : NSColor.blackColor()
        if NSEqualRanges(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange) {
            textStorage.removeAttribute(NSBackgroundColorAttributeName, range: NSMakeRange(0, textStorage.length))
        }
        self.mouseWasDragged = true
    }
    
    override func moveWordRightAndModifySelection(sender: AnyObject?) {
        super.moveWordRightAndModifySelection(sender)
        guard let textStorage = self.textStorage else { return }
        
        var index = NSMaxRange(self.selectedRange())
        if index - 1 < 0 { return }
        
        if textStorage.tokenStringAtIndex(index - 1) != nil {
            let area = NSMakeRange(index - 2, 3)
            textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
            index++
        }

        
        let selected = self.lastSelectedTokenPosition.selected && self.lastSelectedTokenPosition.oldRange.location >= index ? false : true
        self.setTokenStatus(selected, startIndex: self.selectedRange().location, endIndex: index)
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(index, 0)
        self.lastSelectedTokenPosition.direction = .Right
        
        self.setSelectedRange(NSMakeRange(index, 0))
        self.insertionPointColor = index != self.lastSelectedTokenPosition.oldRange.location ? NSColor.whiteColor() : NSColor.blackColor()
        
        if NSEqualRanges(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange) {
            textStorage.removeAttribute(NSBackgroundColorAttributeName, range: NSMakeRange(0, textStorage.length))
        }
        self.mouseWasDragged = true
        
    }
    
    override func moveLeftAndModifySelection(sender: AnyObject?) {
        guard let textStorage = self.textStorage else { return }
        // Do not want to do anything if the range is at the beginning
        if self.selectedRange().location == 0 { return }
        
        //Force the selection since we are not calling super here, Move to left by once cursor point
        var newLocation = self.selectedRange().location - 1
        
        if self.lastSelectedTokenPosition.selected && self.lastSelectedTokenPosition.direction == .None {
            //NOTE: This is a special case Mouse Double Click text Selection handling
            newLocation = self.lastSelectedTokenPosition.oldRange.location
            //Continuously update the new range (disregard the length, just like in drag)
            self.lastSelectedTokenPosition.oldRange = self.lastSelectedTokenPosition.newRange
            self.lastSelectedTokenPosition.newRange = NSMakeRange(newLocation, 0)
            self.lastSelectedTokenPosition.direction = .Left
            
            newLocation -= 2
        }
        
        let index = newLocation
        
        if textStorage.tokenStringAtIndex(index - 1) != nil {
            let force = self.lastSelectedTokenPosition.direction == .Right ? (self.mouseWasDragged ? false : true) : false
            (self.delegate as! RSTokenField).setToken(true, atIndex: index - 1, force: force)
            self.setSelectedRange(NSMakeRange(index + 1, 0))
            
            newLocation = index - 2
            
            if force {
                //This means we need to "select" the next token or character to the right
                self.setSelectedRange(NSMakeRange(newLocation, 0))
                self.moveLeftAndModifySelection(self)
                return
            }
        } else {
            let area = NSMakeRange(index, 1)
            var disColored = false
            
            if let c = textStorage.attribute(NSBackgroundColorAttributeName, atIndex: area.location, effectiveRange: nil), color = c as? NSColor {
                if color == NSColor.controlHighlightColor() {
                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                    disColored = true
                }
            }
            if !disColored {
                textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
            }
        }
    
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(newLocation, 0)
        self.lastSelectedTokenPosition.direction = .Left
        
        self.setSelectedRange(NSMakeRange(newLocation, 0))
        self.insertionPointColor = newLocation != self.lastSelectedTokenPosition.oldRange.location ? NSColor.whiteColor() : NSColor.blackColor()
        
        self.mouseWasDragged = true
    }
    
    override func moveRightAndModifySelection(sender: AnyObject?) {
        guard let textStorage = self.textStorage else { return }
        // Do not want to do anything if the range is at the beginning
        if self.selectedRange().location == textStorage.length { return }
        
        //Force the selection since we are not calling super here, Move to left by once cursor point
        let index = self.selectedRange().location
        var newLocation = index + 1
        
        if textStorage.isWhiteSpace(index) && textStorage.tokenStringAtIndex(index + 1) != nil {
            if textStorage.tokenStringAtIndex(index + 1) != nil {
                let force = self.lastSelectedTokenPosition.direction == .Left ? (self.mouseWasDragged ? false : true) : false
                (self.delegate as! RSTokenField).setToken(true, atIndex: index + 1, force: force)
                self.setSelectedRange(NSMakeRange(index, 0))
                newLocation = index + 3
                
                if force {
                    //This means we need to "select" the next token or character to the right
                    self.setSelectedRange(NSMakeRange(newLocation, 0))
                    self.moveRightAndModifySelection(self)
                    return
                }
                
            }
        } else {
            let area = NSMakeRange(index, 1)
            var disColored = false
            
            if let c = textStorage.attribute(NSBackgroundColorAttributeName, atIndex: area.location, effectiveRange: nil), color = c as? NSColor {
                if color == NSColor.controlHighlightColor() {
                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                    disColored = true
                }
            }
            if !disColored {
                textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
            }
        }
        
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(newLocation, 0)
        self.lastSelectedTokenPosition.direction = .Right
        
        self.setSelectedRange(NSMakeRange(newLocation, 0))
        self.insertionPointColor = newLocation != self.lastSelectedTokenPosition.oldRange.location ? NSColor.whiteColor() : NSColor.blackColor()
        
        self.mouseWasDragged = true
    }
}

//MARK: MOUSE EVENTS
extension RSTokenTextView {
    // Use Mouse Loop Tracking Approach
    override func mouseDown(theEvent: NSEvent) {
        guard let window = self.window else { return }
        
        //Check if the mouse is down while holding shift key
        if theEvent.modifierFlags.contains(.ShiftKeyMask) {
            self.handleShiftPlusMouseDown(theEvent)
            return
        }
        
        var dragActive = self.mouseDownEvent(theEvent)
        
        while dragActive {
            if let event = window.nextEventMatchingMask(Int(NSEventMask.LeftMouseDraggedMask.union(.LeftMouseUpMask).rawValue), untilDate: NSDate.distantFuture(), inMode: NSEventTrackingRunLoopMode, dequeue: true) {
                switch event.type {
                case .LeftMouseDragged:
                    self.mouseDraggedEvent(event)
                    break
                case .LeftMouseUp:
                    dragActive = false
                    self.mouseUpEvent(event)
                    break
                default:
                    break
                }
            }
        }
    }
    
    private func mouseDownEvent(theEvent: NSEvent) -> Bool {
        guard let textStorage = self.textStorage else { return false }
        // Reset token position values
        self.clearLastTokenPosition()
        
        if theEvent.type == .LeftMouseDown {
            guard let eventMetaData = self.getMetaDataForMouseEvent(theEvent) else { return false }
            
            let charIndex = eventMetaData["charIndex"] as! Int
            let pos = (eventMetaData["position"] as! NSValue).pointValue
            let bounds = (eventMetaData["bounds"] as! NSValue).rectValue
            
            if theEvent.clickCount == 3 {
                self.selectAll(self)
                return false
            } else if theEvent.clickCount == 2 {
                // Handle double click
                if textStorage.tokenStringAtIndex(charIndex) != nil {
                    self.handleDoubleClickOnToken(charIndex)
                } else {
                    //We Call super here to get the text select functionality for free
                    super.mouseDown(theEvent)
                    self.handleDoubleClickOnText()
                    return false
                }
            } else {
                if pos.x >= bounds.origin.x && pos.x <= bounds.origin.x + bounds.size.width {
                    if let attribute = (textStorage.attribute(NSAttachmentAttributeName, atIndex: charIndex, effectiveRange: nil)) {
                        if attribute is RSTextAttachment {
                            let buttonRect = ((attribute as! RSTextAttachment).tokenView?.type.frame)!
                            let imageViewRect = ((attribute as! RSTextAttachment).tokenView?.imageView.frame)!
                            let frameToCompare = NSMakeRect(bounds.origin.x, bounds.origin.y, buttonRect.width + imageViewRect.width, buttonRect.height)
                            
                            if pos.x >= frameToCompare.origin.x && pos.x <= frameToCompare.origin.x + frameToCompare.size.width {
                                // left click on token type
                                (self.delegate as! RSTokenField).setToken(typeOnly: true, selected: true, atIndex: charIndex)
                                self.setSelectedRange(NSMakeRange(charIndex + 2, 0))
                                self.insertionPointColor = NSColor.whiteColor()
                                
                                if let menu = (self.delegate as! RSTokenField).textView(self, menuForToken: ((attribute as! RSTextAttachment).tokenView?.title.stringValue)!, atIndex: charIndex) {
                                    let point = CGPointMake(bounds.origin.x + 2, buttonRect.height + 10)
                                    menu.popUpMenuPositioningItem(menu.itemAtIndex(0), atLocation: point, inView: self)
                                    return false
                                }
                            } else {
                                // left click on token title
                                self.handleSingleClickOnText(charIndex)
                            }
                        }
                    } else {
                        //This piece of code is executed when a token is not selected
                        if charIndex > 0 && textStorage.tokenStringAtIndex(charIndex - 1) != nil {
                            //We get here when the mouse is clicked on the white space right after a token, we offset it by 1
                            self.setSelectedRange(NSMakeRange(charIndex + 1, 0))
                            self.insertionPointColor = NSColor.blackColor()
                        } else {
                            (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: charIndex)
                            self.setSelectedRange(NSMakeRange(charIndex, 0))
                            self.insertionPointColor = NSColor.blackColor()
                        }
                    }
                } else {
                    (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: charIndex)
                    self.setSelectedRange(NSMakeRange(charIndex + 1, 0))
                    self.insertionPointColor = NSColor.blackColor()
                }
            }
        }
        
        return true
    }
    
    private func mouseDraggedEvent(theEvent: NSEvent) {
        self.mouseWasDragged = true
        
        guard let eventMetaData = self.getMetaDataForMouseEvent(theEvent) else { return }
        
        let charIndex = eventMetaData["charIndex"] as! Int
        let fraction = eventMetaData["fraction"] as! CGFloat
        
        var finalIndex = charIndex
        self.lastSelectedTokenPosition.direction = charIndex >= self.selectedRange().location ? .Right : .Left
        
        if textStorage?.tokenStringAtIndex(charIndex) != nil {
            finalIndex = fraction < 0.5 ? charIndex : charIndex + 2
        }
        
        self.mouseDragged(toIndex: finalIndex, direction: self.lastSelectedTokenPosition.direction)
        
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = self.selectedRange
        }
        
        self.lastSelectedTokenPosition.newRange = NSMakeRange(finalIndex, 0)
    }
    
    private func mouseUpEvent(theEvent: NSEvent) {
        guard let textStorage = self.textStorage else { return }
        
        let index = self.lastSelectedTokenPosition.newRange.location
        var selectedRange = NSMakeRange(index, 0)
        var insertionPointcolor = NSColor.whiteColor()
        
        //HACK:Everything below here is for an ugly hack to set the text selection till the end of the textStorage length
        guard let eventMetaData = self.getMetaDataForMouseEvent(theEvent) else { return }
        
        let charIndex = eventMetaData["charIndex"] as! Int
        let fraction = eventMetaData["fraction"] as! CGFloat
        //Until Here
        
        if self.mouseWasDragged {
            if self.lastSelectedTokenPosition.direction == .Right {
                if (textStorage.tokenStringAtIndex(index) != nil) && fraction > 0.5 {
                    if index < textStorage.length - 1 {
                        selectedRange = NSMakeRange(index + 2, 0)
                    } else {
                        selectedRange = NSMakeRange(textStorage.length, 0)
                    }
                } else if (textStorage.tokenStringAtIndex(index) != nil) && fraction < 0.5{
                    //Even though the mouse ended up being on a token the fraction is < 0.5 hence we do not set it as selected yet
                    selectedRange = NSMakeRange(index - 1, 0)
                } else if fraction == 1 && charIndex == textStorage.length - 1 {
                    //HACK:This combined with the if conidtion in the mouseDrag method for direction == Right
                    //is an ugly hack to keep the selection till the end of the text Storage length, Feel dirty doing this
                    let area = NSMakeRange(charIndex, 1)
                    textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                    selectedRange = NSMakeRange(textStorage.length, 0)
                }
            } else {
                if (textStorage.tokenStringAtIndex(index) != nil) && fraction < 0.5 {
                    if index > 0 {
                        selectedRange = NSMakeRange(index - 1, 0)
                    } else {
                        selectedRange = NSMakeRange(0, 0)
                    }
                } else if (textStorage.tokenStringAtIndex(index) != nil) && fraction > 0.5 {
                    //Even though the mouse ended up being on a token the fraction is >d 0.5 hence we do not set it as selected yet
                    selectedRange = NSMakeRange(index + 2, 0)
                } else if fraction == 1 && charIndex == textStorage.length - 1 {
                    //HACK:This combined with the if conidtion in the mouseDrag method for direction == Right
                    //is an ugly hack to keep the selection till the end of the text Storage length, Feel dirty doing this
                    let area = NSMakeRange(charIndex, 1)
                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                    selectedRange = NSMakeRange(textStorage.length, 0)
                    insertionPointcolor = NSColor.blackColor()
                }
            }
            
            self.lastSelectedTokenPosition.newRange = selectedRange
            self.insertionPointColor = insertionPointcolor
            self.setSelectedRange(selectedRange)
        }
    }

}

//MARK: HELPERS
extension RSTokenTextView {
    private func mouseDragged(toIndex index: Int, direction: RSTokenPosition.Direction) {
        guard let textStorage = self.textStorage else { return }
        
        var startIndex = self.lastSelectedTokenPosition.selected ? self.lastSelectedTokenPosition.newRange.location : self.selectedRange().location
        var endIndex = index
        
        if direction == .Left {
            endIndex = self.lastSelectedTokenPosition.selected ? self.lastSelectedTokenPosition.newRange.location : self.selectedRange().location
            startIndex = index
        }
        
        if startIndex == endIndex {
            return
        } else if startIndex > endIndex {
            //Unselect all the selected tokens
            self.setTokenStatus(false, startIndex: endIndex, endIndex: startIndex)
            return
        } else {
            switch direction {
            case .Left:
                if self.selectedRange().location < textStorage.length {
                    //Unselect everything from endIndex till TextStorage.Length
                    self.setTokenStatus(false, startIndex: self.selectedRange().location, endIndex: textStorage.length)
                }
                break
            case .Right:
                if self.selectedRange().location > 0 {
                    //Unselect everything from endIndex till TextStorage.Length
                    self.setTokenStatus(false, startIndex: 0, endIndex: self.selectedRange().location - 1)
                }
                break
            default:
                break
            }
            
            self.setTokenStatus(true, startIndex: startIndex, endIndex: endIndex)
        }
    }
    
    private func handleShiftPlusMouseDown(theEvent: NSEvent) {
        //Set the old range to selected range location if its not already selected
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        
        let charIndex = self.getMetaDataForMouseEvent(theEvent)!["charIndex"] as! Int
        let fraction = self.getMetaDataForMouseEvent(theEvent)!["fraction"] as! CGFloat
        var startIndex = self.lastSelectedTokenPosition.oldRange.location
        var endIndex = charIndex
        
        //fraction distance fron the end of the glyph or character
        if fraction > 0.5 && self.textStorage?.tokenStringAtIndex(charIndex) == nil {
            endIndex = charIndex + 1
        }
        
        let nearestRange = self.nearestRangeFor(endIndex, oldRange: self.lastSelectedTokenPosition.oldRange, newRange: self.lastSelectedTokenPosition.newRange)
        
        if NSEqualRanges(self.lastSelectedTokenPosition.oldRange, nearestRange) {
            //This could mean the text cursor is either between new and old range or after old range
            if self.lastSelectedTokenPosition.newRange.location != NSNotFound {
                startIndex = self.lastSelectedTokenPosition.newRange.location
                //Update oldRange to startIndex as the newRange is updated below and is about to change
                self.lastSelectedTokenPosition.oldRange = NSMakeRange(startIndex, 0)
            }
        }
        
        //Erase any selection that is out of selected range
        self.setTokenStatus(false, startIndex: nearestRange.location, endIndex: endIndex)
        //Set the current selection after erasing the previous selection
        self.setTokenStatus(true, startIndex: startIndex, endIndex: endIndex)
        
        
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(endIndex, 0)
        self.lastSelectedTokenPosition.direction = startIndex > endIndex ? .Left : .Right
        self.mouseWasDragged = true
        
        self.setSelectedRange(NSMakeRange(endIndex, 0))
        self.insertionPointColor = startIndex != endIndex ? NSColor.whiteColor() : NSColor.blackColor()
    }
    
    private func clearLastTokenPosition() {
        if self.mouseWasDragged {
            (self.delegate as! RSTokenField!).setToken(typeOnly: false, selected: true, atIndex: NSNotFound)
            self.mouseWasDragged = false
        }
    }
    
    private func handleDoubleClickOnToken(charIndex: Int) {
        guard let textStorage = self.textStorage else { return }
        var stem = ""
        var curRange = NSMakeRange(charIndex, 0)
        while curRange.location != NSNotFound {
            let attribute = textStorage.attribute(NSAttachmentAttributeName, atIndex: curRange.location, effectiveRange: &curRange)
            if attribute is RSTextAttachment {
                stem = (attribute as! RSTextAttachment).tokenView.tokenItem.stem
                break
            }
            curRange = NSMakeRange(curRange.location > 0 ? curRange.location - 1 : NSNotFound, 0)
        }
        
        self.mouseWasDragged = true
        self.setSelectedRange(NSMakeRange(charIndex - 1, 3))
        self.delete(nil)
        self.insertText(stem, replacementRange: self.selectedRange())
        self.insertionPointColor = NSColor.blackColor()
    }
    
    private func handleDoubleClickOnText() {
        self.insertionPointColor = NSColor.whiteColor()
        self.setTokenStatus(true, startIndex: self.selectedRange().location, endIndex: NSMaxRange(self.selectedRange()))
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(self.selectedRange().location, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(NSMaxRange(self.selectedRange()), 0)
        self.lastSelectedTokenPosition.direction = .None
        
        self.setSelectedRange(NSMakeRange(NSMaxRange(self.selectedRange()), 0))
        self.mouseWasDragged = true
    }
    
    private func handleSingleClickOnText(charIndex: Int) {
        // Insert white space after the token
        (self.delegate as! RSTokenField).setToken(typeOnly: false, selected: true, atIndex: charIndex)
        
        self.insertionPointColor = NSColor.whiteColor()
        
        
        //Set the old range if its not already selected (Could be selected due to drag)
        if !self.lastSelectedTokenPosition.selected {
            self.lastSelectedTokenPosition.selected = true
            self.lastSelectedTokenPosition.oldRange = NSMakeRange(charIndex, 0)
        }
        //Continuously update the new range (disregard the length, just like in drag)
        self.lastSelectedTokenPosition.newRange = NSMakeRange(charIndex + 2, 0)
        self.lastSelectedTokenPosition.direction = .None
        
        self.setSelectedRange(self.lastSelectedTokenPosition.newRange)
    }
    
    
    private func getMetaDataForMouseEvent(theEvent: NSEvent) -> [String:AnyObject]? {
        guard let layoutManager = self.layoutManager,textContainer = self.textContainer else { return nil }
        
        let pos = self.convertPoint(theEvent.locationInWindow, fromView: nil)
        let appliedPos = CGPointMake(pos.x, self.frame.size.height/2)
        
        var fraction: CGFloat = 0
        let glyphIndex = layoutManager.glyphIndexForPoint(appliedPos, inTextContainer: textContainer, fractionOfDistanceThroughGlyph: &fraction)
        let bounds = layoutManager.boundingRectForGlyphRange(NSMakeRange(glyphIndex, 1), inTextContainer: textContainer)
        let charIndex = layoutManager.characterIndexForGlyphAtIndex(glyphIndex)
        
        return ["charIndex" : charIndex, "fraction" : fraction, "bounds" : NSValue.init(rect: bounds), "position" : NSValue.init(point: pos)]
    }
    
    private func setTokenStatus(selected: Bool, startIndex from: Int, endIndex to: Int) {
        guard let textStorage = self.textStorage else { return }
        var f = from, t = to
        if from > to {
            t = from
            f = to
        }
        
        for var i = f; i < t; i++ {
            if textStorage.tokenStringAtIndex(i) != nil {
                let range = self.selectedRange()
                (self.delegate as! RSTokenField).setToken(selected, atIndex: i, force: true)
                self.setSelectedRange(range)
            } else if ((i < textStorage.length && textStorage.tokenStringAtIndex(i + 1) != nil) || (i > 0 && textStorage.tokenStringAtIndex(i - 1) != nil)) {
                //Nothing to do here
            } else {
                let area = NSMakeRange(i, i < textStorage.length ? 1 : 0)
                if selected {
                    textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                } else {
                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                }
            }
        }
    }
    
    private func nearestRangeFor(index: Int, oldRange: NSRange, newRange: NSRange) -> NSRange {
        if abs(oldRange.location - index) < abs(newRange.location - index) {
            return oldRange
        } else {
            return newRange
        }
    }
}

//MARK: DELETE, CUT, COPY, PASTE Operations
extension RSTokenTextView {
    override func delete(sender: AnyObject?) {
        self.undoManager?.registerUndoWithTarget(self, handler: {[rangeToDelete = self.selectedRange(), selected = self.mouseWasDragged,
            lastSelectedTokenPosition = self.lastSelectedTokenPosition] (RSTokenTextView) -> () in
            self.setTokenStatus(selected, startIndex: rangeToDelete.location, endIndex: NSMaxRange(rangeToDelete))
            
            self.lastSelectedTokenPosition = lastSelectedTokenPosition
            self.mouseWasDragged = selected
            
            self.setSelectedRange(NSMakeRange(NSMaxRange(lastSelectedTokenPosition.newRange), 0))
            self.insertionPointColor = selected ? NSColor.whiteColor() : NSColor.blackColor()
            })
        self.undoManager?.setActionName(NSLocalizedString("Undo - Delete", comment:"Revert Delete"))
        
        super.delete(sender)
    }
    
    override func cut(sender: AnyObject?) {
        super.cut(sender)
        
        let range = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
        let mutableAttrString = self.textStorage?.attributedSubstringFromRange(range)
        
        //Erase previously copied string, if any
        copiedString = NSMutableAttributedString.init(string: "")
        copiedString?.appendAttributedString(mutableAttrString!)
        
        if let string = copiedString where string.length > 0 {
            let pasteboardItem = RSTokenPasteboardItem.init(withAttributedString: string)
            let pasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.writeObjects([pasteboardItem])
        }
        
        self.setSelectedRange(range)
        self.delete(nil)
        //Reset this flag to clear out the selection ranges
        mouseWasDragged = false
        self.insertionPointColor = NSColor.blackColor()
    }
    
    override func paste(sender: AnyObject?) {
        super.paste(sender)
        
        let pasteboard = NSPasteboard.generalPasteboard()
        let classArray = [RSTokenPasteboardItem.classForCoder(), NSString.classForCoder()]
        let options = [String : AnyObject]()
        
        let ok = pasteboard.canReadObjectForClasses(classArray, options: options)
        
        if ok {
            self.undoManager?.beginUndoGrouping()
            if mouseWasDragged {
                //There is currently selected Text
                let range = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
                self.replaceCharactersInRange(range, withString: "")
            }

            if let objectsToPaste = pasteboard.readObjectsForClasses(classArray, options: options) {
                if let item = objectsToPaste[0] as? RSTokenPasteboardItem {
                    super.insertText(item.attributedString, replacementRange: self.selectedRange())
                } else if let item = objectsToPaste[0] as? String {
                    super.insertText(NSAttributedString.init(string: item), replacementRange: self.selectedRange())
                }
            }
            self.undoManager?.setActionName("Undo - Paste")
            //Set everything unselected
            self.setTokenStatus(false, startIndex: 0, endIndex: (self.textStorage?.length)!)
            //Reset the selected token position
            mouseWasDragged = false
            //We should also update the token field data source when something is pasted to the textview
            (self.delegate as! RSTokenField).textView(self, didChangeTokens: self.tokenArray())
            
            self.undoManager?.endUndoGrouping()
        }
    }
    
    override func copy(sender: AnyObject?) {
        super.copy(sender)
        
        let range = NSUnionRange(self.lastSelectedTokenPosition.oldRange, self.lastSelectedTokenPosition.newRange)
        
        let mutableAttrString = self.textStorage?.attributedSubstringFromRange(range)
        
        //Erase previously copied string, if any
        copiedString = NSMutableAttributedString.init(string: "")
        copiedString?.appendAttributedString(mutableAttrString!)
        
        //Write Content to the pasteboard
        if let string = copiedString where string.length > 0 {
            let pasteboardItem = RSTokenPasteboardItem.init(withAttributedString: string)
            let pasteboard = NSPasteboard.generalPasteboard()
            pasteboard.clearContents()
            pasteboard.writeObjects([pasteboardItem])
        }
        
        self.insertionPointColor = NSColor.whiteColor()
    }
}

//MARK : UNDO Manager
extension RSTokenTextView {
    func undo(sender: AnyObject?) {
        //This is needed when there is no "Edit" Menu
        self.undoManager?.undo()
    }
    
    func redo(sender: AnyObject?) {
        self.undoManager?.redo()
    }
    
    private func dumpUndoStack() {
        let aClass : NSUndoManager.Type = (self.undoManager?.dynamicType)!
        var propertiesCount : CUnsignedInt = 0
        let propertiesInAClass : UnsafeMutablePointer<Ivar> = class_copyIvarList(aClass, &propertiesCount)
        var propValue : AnyObject? = nil
        
        var redoStack : AnyObject? = nil
        
        for var i = 0; i < Int(propertiesCount); i++ {
            let propName:NSString = NSString(CString: ivar_getName(propertiesInAClass[Int(i)]), encoding: NSUTF8StringEncoding)!
            
            if propName == "_undoStack" {
                propValue = self.undoManager!.valueForKey("_undoStack")!
            }
            
            if propName == "_redoStack" {
                redoStack = self.undoManager!.valueForKey("_redoStack")!
            }
            Swift.print(propName)
        }
        
        NSLog("(%d entries) %@", propValue!.count, propValue!.description)
        NSLog("(%d entries) %@", redoStack!.count, redoStack!.description)
    }
    
    func didRedo(notification: NSNotification) {
        self.setTokenStatus(self.mouseWasDragged, startIndex: self.lastSelectedTokenPosition.oldRange.location, endIndex:self.lastSelectedTokenPosition.newRange.location)
        self.didRedoDelete = true
    }
    
    func didUndo(notification: NSNotification) {
        self.setSelectedRange(NSMakeRange(NSMaxRange(self.selectedRange()), 0))
        self.didRedoDelete = false
    }
}