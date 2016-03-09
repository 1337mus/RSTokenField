//
//  RSTokenTextView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTokenTextView: NSTextView {

    override func resignFirstResponder() -> Bool {
        self.tokenizeRemainingText()
        return super.resignFirstResponder()
    }
    
    override func setMarkedText(aString: AnyObject, selectedRange: NSRange, replacementRange: NSRange) {
        super.setMarkedText(aString, selectedRange: selectedRange, replacementRange: replacementRange)
    }
    
    override func insertText(aString: AnyObject, replacementRange: NSRange) {
        let insertionIndex = self.selectedRange().location
        if insertionIndex != NSNotFound {
            let completionController = RSTokenCompletionWindowController.sharedInstance
            
            if completionController.isDisplayingCompletions() {
                completionController.insertText(aString)
            } else {
                let startingStemRange = self.rangeForCompletion()
                let selectionIndex = self.selectedRange().location - startingStemRange.location
                let replacedText = ((self.textStorage?.string)! as NSString).substringWithRange(startingStemRange)
                
                let startingStem = NSMutableString(string: replacedText)
                startingStem.insertString(aString as! String, atIndex: selectionIndex)
                
                completionController.insertText(startingStem)
            }
            
            if insertionIndex <= self.textStorage?.length {
                let stemRange = self.completionRange()
                
                completionController.displayCompletionsForStem(completionController.rawStem, forTextView: self, forRange: stemRange)
            }
        }
        
        // Whenever a character is entered mark all token as unselected
        self.insertionPointColor = NSColor.blackColor()
        (self.delegate as! RSTokenField).setToken(true, atIndex: selectedRange.location)
        self.setSelectedRange(NSMakeRange(insertionIndex, 0))
        super.insertText(aString, replacementRange: replacementRange)
    }
    
    override func doCommandBySelector(aSelector: Selector) {
        let completionController = RSTokenCompletionWindowController.sharedInstance
        if aSelector == "deleteBackward:" {
            
            let currentTokens = self.tokenArray()
            var finalSelectedRange = 0
            if self.selectedRange.length > 0 {
                let deleteRange = self.selectedRange
                self.textStorage?.replaceCharactersInRange(deleteRange, withString: "")
                self.setSelectedRange(NSMakeRange(deleteRange.location, 0))
                if completionController.isDisplayingCompletions() {
                    self.abandonCompletion()
                }
            } else if self.selectedRange.location >= 0 {
                
                var deleteIndex = self.selectedRange.location + 1
                var selectedTokenIndex = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(deleteIndex, 0))
                if selectedTokenIndex.location == NSNotFound {
                    deleteIndex = self.selectedRange.location - 2
                    selectedTokenIndex = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(deleteIndex, 0))
                }
                
                if selectedTokenIndex.location != NSNotFound {
                    self.textStorage?.replaceCharactersInRange(NSMakeRange(deleteIndex, 1), withString: "")
                    finalSelectedRange = deleteIndex - 1
                    self.insertionPointColor = NSColor.blackColor()
                } else {
                
                    deleteIndex = self.selectedRange.location - 2
                    
                    if (deleteIndex > 0 && (self.textStorage?.tokenStringAtIndex(deleteIndex)) != nil) {
                        (self.delegate as! RSTokenField).setToken(true, atIndex: deleteIndex)
                        finalSelectedRange = deleteIndex - 1
                        self.insertionPointColor = NSColor.whiteColor()
                    } else {
                        let deleteRange = ((self.textStorage?.string)! as NSString).rangeOfComposedCharacterSequenceAtIndex(deleteIndex + 1)
                        self.textStorage?.replaceCharactersInRange(deleteRange, withString: "")
                        finalSelectedRange = deleteRange.location
                        if completionController.isDisplayingCompletions() {
                            completionController.tearDownWindow()
                        }
                        self.insertionPointColor = NSColor.blackColor()
                    }
                }
            }
            
            if self.tokenArray() != currentTokens {
                let delegate = self.delegate as! RSTokenField
                delegate.textView(self, didChangeTokens: self.tokenArray())
            }
            
            self.setSelectedRange(NSMakeRange(finalSelectedRange, 0))
            
            return
        } else if aSelector == "moveLeft:" {
            self.abandonCompletion()
            let selectedRange = self.selectedRange()
            if selectedRange.location >= 0 && (selectedRange.location + selectedRange.length) <= self.textStorage?.length {
                let selectedIndex = selectedRange.location - 2
                if self.insertionPointColor == NSColor.whiteColor() {
                    let nearestSelectedRange = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(selectedRange.location - 2, 0))
                    (self.delegate as! RSTokenField).setToken(true, atIndex: selectedRange.location + 2)
                    self.insertionPointColor = NSColor.blackColor()
                    if nearestSelectedRange.location == NSNotFound {
                        self.setSelectedRange(NSMakeRange(selectedRange.location, 0))
                    } else {
                        self.setSelectedRange(NSMakeRange(nearestSelectedRange.location - 1, 0))
                    }
                    return
                } else if (selectedIndex >= 0 && (self.textStorage?.tokenStringAtIndex(selectedIndex)) != nil) {
                    (self.delegate as! RSTokenField).setToken(true, atIndex: selectedIndex)
                    self.setSelectedRange(NSMakeRange(selectedIndex - 1, 0))
                    self.insertionPointColor = NSColor.whiteColor()
                    return
                } else {
                    self.insertionPointColor = NSColor.blackColor()
                }
            }
        } else if aSelector == "moveRight:" {
            self.abandonCompletion()
            let selectedRange = self.selectedRange()
            if selectedRange.location >= 0 && selectedRange.location <= self.textStorage?.length {
                let selectedIndex = selectedRange.location + 1
                if self.insertionPointColor == NSColor.whiteColor() {
                    let nearestSelectedRange = (self.delegate as! RSTokenField).selectedTokenRangeForGivenRange(NSMakeRange(selectedRange.location + 1, 0))
                    (self.delegate as! RSTokenField).setToken(true, atIndex: selectedRange.location - 1)
                    self.insertionPointColor = NSColor.blackColor()
                    if nearestSelectedRange.location == NSNotFound {
                        self.setSelectedRange(NSMakeRange(selectedRange.location, 0))
                    } else {
                        self.setSelectedRange(NSMakeRange(nearestSelectedRange.location + 2, 0))
                    }
                    return
                } else if ((self.textStorage?.tokenStringAtIndex(selectedIndex)) != nil) {
                    (self.delegate as! RSTokenField).setToken(true, atIndex: selectedIndex)
                    self.setSelectedRange(NSMakeRange(selectedIndex + 2, 0))
                    self.insertionPointColor = NSColor.whiteColor()
                    return
                } else {
                    self.insertionPointColor = NSColor.blackColor()
                }
            }
        }
        super.doCommandBySelector(aSelector)
    }
    
    
    
    //MARK: Token Methods
    func tokenForString(aString: String) -> NSAttributedString {
        var topLevelObjects: NSArray?
        NSBundle.mainBundle().loadNibNamed("RSTokenView",
            owner:self, topLevelObjects:&topLevelObjects)
        
        var view: RSTokenView!
        for o in topLevelObjects! {
            if o is RSTokenView {
                view = o as! RSTokenView
                view!.tokenItem = RSTokenItem.init(type: "Title", title: aString)
            }
        }
        
        let attachment = RSTextAttachment.init(withTokenView: view)
        
        let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
        attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
        attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
        
        return attributeString
    }
    
    // Used to delete Tokens
    func countOfTokensInRange(aRange: NSRange) -> Int {
        return (self.textStorage?.countOfRSTokensInRange(aRange))!
    }
    
    
    func tokenArray() -> [RSTokenItem] {
        var tokenArray = [RSTokenItem]()
        
        let textStorageLength = self.textStorage?.length
        if textStorageLength > 0 {
            var curRange = NSMakeRange(textStorageLength! - 1, 0)
            while curRange.location != NSNotFound {
                let attribute = self.textStorage?.attribute(NSAttachmentAttributeName, atIndex: curRange.location, effectiveRange: &curRange)
                if attribute is RSTextAttachment {
                    tokenArray.append((attribute as! RSTextAttachment).tokenView.tokenItem)
                }
                curRange = NSMakeRange(curRange.location > 0 ? curRange.location - 1 : NSNotFound, 0)
            }
        }
        return tokenArray
    }
    
    func setTokenArray(tokenArray: [RSTokenItem]) {
        let attributedString = NSMutableAttributedString.init()
        
        for token in tokenArray.reverse() {
            attributedString.appendAttributedString(self.tokenForString(token.tokenTitle))
        }
        self.textStorage?.setAttributedString(attributedString)
    }
    
    func tokenizeRemainingText() {
        let delegate = self.delegate as! RSTokenField
        delegate.textView(self, didChangeTokens: self.tokenArray())
    }
    
    // Used to Insert Tokens
    func rangeForCompletion() -> NSRange {
        let effectiveRange = self.selectedRange()
        var startLocation = self.selectedRange().location
        var endLocation = effectiveRange.location
        let curString = self.textStorage
        
        while Bool(startLocation) && ((curString?.attribute(NSAttachmentAttributeName, atIndex: startLocation - 1, effectiveRange: nil)) == nil) {
            startLocation--
        }
        
        while endLocation < (curString?.length) && ((curString?.attribute(NSAttachmentAttributeName, atIndex: endLocation, effectiveRange: nil)) == nil) {
            endLocation++
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
            self.setSelectedRange(NSMakeRange(min((self.textStorage?.length)!,attributesRange.location + attributesRange.length + 1), 0))
            completionHandler.tearDownWindow()
        }
    }
    
    //MARK: Text Insertion Methods
    func insertTokenForText(tokenText: String, replacementRange: NSRange) {
        let insertionLocation = self.selectedRange().location
        let delegate = self.delegate as! RSTokenField
        if delegate.shouldAddToken(tokenText, atTokenIndex: self.countOfTokensInRange(NSMakeRange(0, replacementRange.location))) {
            let insertiontext = self.tokenForString(tokenText)
            let delegate = self.delegate as! RSTokenField
            super.insertText(insertiontext, replacementRange: replacementRange)
            delegate.textView(self, didChangeTokens: self.tokenArray())
            self.setSelectedRange(NSMakeRange(insertionLocation + 2, 0))
        }
    }
    
    //MARK: handle Mouse clicks
    override func mouseDown(event: NSEvent) {
        if event.type == .LeftMouseDown {
            let pos = self.convertPoint(event.locationInWindow, fromView: nil)
            var fraction: CGFloat = 0
            let glyphIndex = self.layoutManager?.glyphIndexForPoint(pos, inTextContainer: self.textContainer!, fractionOfDistanceThroughGlyph: &fraction)
            
            let bounds = self.layoutManager?.boundingRectForGlyphRange(NSMakeRange(glyphIndex!, 1), inTextContainer: self.textContainer!)
            
            if NSPointInRect(pos, bounds!) {
                let charIndex = self.layoutManager?.characterIndexForGlyphAtIndex(glyphIndex!)
                if let attribute = (self.textStorage?.attribute(NSAttachmentAttributeName, atIndex: charIndex!, effectiveRange: nil)) {
                    if attribute is RSTextAttachment {
                        let buttonRect = ((attribute as! RSTextAttachment).tokenView?.type.frame)!
                        let frameToCompare = NSMakeRect((bounds?.origin.x)!, bounds!.origin.y, buttonRect.width, buttonRect.height)
                        if NSPointInRect(pos, frameToCompare) {
                            if let menu = (self.delegate as! RSTokenField).textView(self, menuForToken: ((attribute as! RSTextAttachment).tokenView?.title.stringValue)!, atIndex: charIndex!) {
                                let point = CGPointMake((bounds?.origin.x)! + 2, buttonRect.height)
                                menu.popUpMenuPositioningItem(menu.itemAtIndex(0), atLocation: point, inView: self)
                            }
                        }
                    }
                }
            }
        }
    }
    
}
