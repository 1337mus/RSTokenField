//
//
//  RSTokenField.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

protocol RSTokenFieldDelegate : NSTextFieldDelegate {
    func tokenField(tokenField: RSTokenField, completionsForSubstring subString: String) -> [RSTokenItemType]
    func tokenField(tokenField: RSTokenField, didChangeTokens tokens: [RSTokenItem])
    func tokenField(tokenField: RSTokenField, willChangeTokens tokens: [RSTokenItem])
    func tokenField(tokenField: RSTokenField, shouldAddToken token: String, atIndex index: Int) -> Bool
    func tokenField(tokenField: RSTokenField, menuForToken string: String, atIndex index: Int) -> NSMenu
}

class RSTokenField: NSTextField {

    private var fieldEditor: RSTokenTextView? = nil
    private var textSelected: Bool = false
    private var textSelectedAll: Bool = false
    
    private var _tokenArray: [RSTokenItemType]? = nil
    
    var tokenArray: [RSTokenItemType]!  {
        get {
            return self._tokenArray ?? [RSTokenItemType]()
        }
        
        set {
            if newValue != nil {
                    let appendedAttributeString = NSMutableAttributedString()
                    
                    let whiteSpace = NSMutableAttributedString(string: " ")
                    
                    for token in newValue.reverse() {
                        if let t = token as? RSTokenItem {
                            var topLevelObjects: NSArray?
                            NSBundle.mainBundle().loadNibNamed("RSTokenView", owner:self, topLevelObjects:&topLevelObjects)
                            
                            var view: RSTokenView!
                            
                            for o in topLevelObjects! {
                                if o is RSTokenView {
                                    view = o as! RSTokenView
                                    view!.tokenItem = t
                                }
                            }
                            
                            let attachment = RSTextAttachment.init(withTokenView: view)
                            
                            let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                            attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                            attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                            
                            appendedAttributeString.appendAttributedString(whiteSpace)
                            appendedAttributeString.appendAttributedString(attributeString)
                            appendedAttributeString.appendAttributedString(whiteSpace)
                            
                        } else if let t = token as? RSTokenItemSection {
                            let sectionName = NSAttributedString.init(string: t.sectionName, attributes: [NSFontAttributeName : NSFont.systemFontOfSize(12)])
                            appendedAttributeString.appendAttributedString(sectionName)
                        }
                    }
                    
                    self.attributedStringValue = appendedAttributeString
                    
                    if let cell = self.cell {
                        self.fieldEditor = cell.fieldEditorForView(self) as? RSTokenTextView
                    }
                    
                    if let textStorage = self.fieldEditor!.textStorage {
                        textStorage.setAttributedString(appendedAttributeString)
                    }
            }
            
            self._tokenArray = newValue
        }
    }
    
    override var objectValue: AnyObject? {
        set {
            self.tokenArray = newValue as? [RSTokenItemType]
        }
        
        get {
            return self.tokenArray as? AnyObject
        }
    }
    
    //MARK: Public Methods
    
    func replaceToken(withType type: String, tokenTitle title: String, atIndex index: Int) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        guard let fieldEditor = self.fieldEditor, let textStorage = fieldEditor.textStorage else {
            return
        }
        
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let val = value, let v = val as? RSTextAttachment {
                let tt = v.tokenView.title.stringValue
                if tt == title && range.location == index {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    
                    let stem = v.tokenView.tokenItem.stem
                    let selected = v.tokenView.selected
                    let typeSelected = v.tokenView.typeSelected
                    
                    v.tokenView.tokenItem = RSTokenItem(type: type, title: title)
                    v.tokenView.tokenItem.stem = stem
                    v.tokenView.selected = selected
                    v.tokenView.typeSelected = typeSelected
                    
                    var arrayIndex = index/3
                    if arrayIndex >= self.tokenArray.count {
                        arrayIndex = self.tokenArray.count - 1
                    }
                    
                    if arrayIndex < 0 {
                        arrayIndex = 0
                    }
                    self.tokenArray[arrayIndex] = v.tokenView.tokenItem
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                    stop.initialize(true)
                }
            }
        }
        
        self.attributedStringValue = mutableAttrString
        textStorage.setAttributedString(mutableAttrString)
    }
    
    func setToken(typeOnly type: Bool, selected: Bool, atIndex index: Int) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let v = value as? RSTextAttachment {
                if range.location == index {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    
                    if type {
                        v.tokenView.typeSelected = selected && !v.tokenView.selected
                    } else {
                        v.tokenView.selected = selected
                    }
                    
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                    
                } else if !type {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    v.tokenView.selected = !selected
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                }
                
            }
        }
        
        self.attributedStringValue = mutableAttrString
        
        if let fieldEditor = self.fieldEditor, let textStorage = fieldEditor.textStorage {
            textStorage.setAttributedString(mutableAttrString)
        }
    }
    
    //TODO: change the method name to toggle token selected status or token visibility
    func setToken(selected: Bool, atIndex index: Int) {
        self.setToken(selected, atIndex: index, force: false)
    }
    
    func setToken(selected: Bool, atIndex index: Int, force: Bool) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let v = value as? RSTextAttachment {
                if range.location == index {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    v.tokenView.selected = force ? selected : !v.tokenView.selected
                    
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                    
                    stop.initialize(true)
                }
                
            }
        }
        
        self.attributedStringValue = mutableAttrString
        
        if let fieldEditor = self.fieldEditor, let textStorage = fieldEditor.textStorage {
            textStorage.setAttributedString(mutableAttrString)
        }
    }
    
    func selectedTokenRangeForGivenRange(aRange: NSRange) -> NSRange {
        var returnRange: NSRange = NSMakeRange(NSNotFound, NSNotFound)
        
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let v = value as? RSTextAttachment {
                if v.tokenView.selected == true && range.location == aRange.location {
                    returnRange = range
                }
            }
        }
        
        return returnRange
    }
}

extension RSTokenField: NSTextViewDelegate {
    
    override func textShouldBeginEditing(textObject: NSText) -> Bool {
        return true
    }
    
    override func textShouldEndEditing(textObject: NSText) -> Bool {
        return true
    }
    
    func textViewDidChangeSelection(notification: NSNotification) {
        if let fieldEditor = self.fieldEditor, textStorage = fieldEditor.textStorage, userInfo = notification.userInfo, var oldRange: NSRange = userInfo["NSOldSelectedCharacterRange"] as? NSRange, let newRange: NSRange = fieldEditor.selectedRange {
            //let selectedText = (fieldEditor.string! as NSString).substringWithRange(fieldEditor.selectedRange)
            //NSLog("selected: %@ - %@", selectedText, NSStringFromRange(fieldEditor.selectedRange))

            if newRange.length == 0 {
                return
            }
            if oldRange.location == newRange.location && oldRange.length == newRange.length {
                return
            }
            if self.textSelected {
                return
            }
            if self.textSelectedAll {
                return
            }
            
            //Close completion handler window
            fieldEditor.abandonCompletion()

            var selectedRange = newRange
            
            // We are going right here
            if NSMaxRange(newRange) > NSMaxRange(oldRange) {
                for var i = newRange.location; i < NSMaxRange(newRange); i++ {
                    self.textSelected = true
                    
                    if textStorage.tokenStringAtIndex(i) != nil {
                        self.setToken(true, atIndex: i, force: newRange.length > 1)
                        selectedRange = NSMakeRange(i + 2 < textStorage.length ? i + 2 : textStorage.length, 0)
                        
                    } else {
                        let string = textStorage.string as NSString
                        if i >= string.length { continue }
                        let unichar = string.characterAtIndex(i)
                        let unicharString = Character(UnicodeScalar(unichar))
                        if unicharString == " " && ((i > 0 && textStorage.tokenStringAtIndex(i - 1) != nil) || (i < textStorage.length && textStorage.tokenStringAtIndex(i + 1) != nil)) {
                            // These are whitespaces surrounding tokens, no need to do anything here
                            self.setToken(true, atIndex: i + 1, force: newRange.length > 1)
                            selectedRange = NSMakeRange(i + 3 < textStorage.length ? i + 3 : textStorage.length, 0)
                            continue
                        } else if i < NSMaxRange(newRange) {
                            let area = NSMakeRange(i, 1)
                            var disColored = false
                            selectedRange = NSMakeRange(i + 1, 0)
                            
                            if let c = textStorage.attribute(NSBackgroundColorAttributeName, atIndex: area.location, effectiveRange: nil), color = c as? NSColor where newRange.length != textStorage.length {
                                if color == NSColor.controlHighlightColor() {
                                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                                    disColored = true
                                }
                            }
                            if !disColored {
                                textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                            }
                        }
                    }
                }
            } else {
                //Left
                for var i = oldRange.location - 1; i >= newRange.location; i-- {
                    self.textSelected = true
                    
                    if textStorage.tokenStringAtIndex(i) != nil {
                        self.setToken(true, atIndex: i, force: newRange.length > 1)
                        selectedRange = NSMakeRange(i > 1 ? i - 1 : 0, 0)
                    } else {
                        let string = textStorage.string as NSString
                        if i >= string.length { continue }
                        let unichar = string.characterAtIndex(i)
                        let unicharString = Character(UnicodeScalar(unichar))
                        if unicharString == " " && ((i > 0 && (textStorage.tokenStringAtIndex(i - 1) != nil) || textStorage.tokenStringAtIndex(i + 1) != nil )) {
                            // These are whitespaces surrounding tokens, no need to do anything here
                            self.setToken(true, atIndex: i - 1, force: newRange.length > 1)
                            selectedRange = NSMakeRange(i > 2 ? i - 2 : 0, 0)
                        } else {
                            let area = NSMakeRange(i, 1)
                            var disColored = false
                            selectedRange = NSMakeRange(i, 0)
                            
                            if let c = textStorage.attribute(NSBackgroundColorAttributeName, atIndex: area.location, effectiveRange: nil), color = c as? NSColor where newRange.length != textStorage.length {
                                if color == NSColor.controlHighlightColor() {
                                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                                    disColored = true
                                }
                            }
                            if !disColored {
                                textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                            }
                            
                        }
                    }
                }
                
            }
            
            
            
            // Handle full text Selection
            if (newRange.location == 0) && newRange.length == textStorage.length && newRange.length > 0 {
                self.textSelectedAll = true
                selectedRange = NSMakeRange(textStorage.length, 0)
                oldRange = NSMakeRange(0, 0)
            }
            
            // Entire Text is selected (cmd + A)
            /*if (newRange.location == 0) && newRange.length == textStorage.length && newRange.length > 0 {
                self.textSelected = true
                hideCaret = true
                
                for var i = 0; i < textStorage.length; i++ {
                    if textStorage.tokenStringAtIndex(i) != nil {
                        self.setToken(true, atIndex: i)
                    } else {
                        let string = textStorage.string as NSString
                        let unichar = string.characterAtIndex(i)
                        let unicharString = Character(UnicodeScalar(unichar))
                        if unicharString == " " && ((i > 0 && textStorage.tokenStringAtIndex(i - 1) != nil) || (i < textStorage.length && textStorage.tokenStringAtIndex(i + 1) != nil)) {
                            // These are whitespaces surrounding tokens, no need to do anything here
                            continue
                        } else {
                            let area = NSMakeRange(i, 1)
                            textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                            textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                        }
                    }
                }
                
                self.textSelectedAll = true
                selectedRange = NSMakeRange(textStorage.length, 0)
                oldRange = NSMakeRange(0, 0)
            } else if textStorage.tokenStringAtIndex(charIndex) != nil {
                self.textSelected = true
                self.setToken(true, atIndex: charIndex)
                hideCaret = true
                if newRange.location < oldRange.location {
                    selectedRange = NSMakeRange(charIndex - 1, 0)
                } else {
                    selectedRange = NSMakeRange(charIndex + 2, 0)
                }
            } else {
                let string = textStorage.string as NSString
                let unichar = string.characterAtIndex(charIndex)
                let unicharString = Character(UnicodeScalar(unichar))
                if unicharString == " " && ((charIndex > 0 && textStorage.tokenStringAtIndex(charIndex - 1) != nil) || (charIndex < textStorage.length && textStorage.tokenStringAtIndex(charIndex + 1) != nil)) {
                    self.textSelected = true
                    
                    if newRange.location < oldRange.location {
                        self.setToken(true, atIndex: charIndex - 1)
                        selectedRange = NSMakeRange(charIndex - 2, 0)
                    } else {
                        self.setToken(true, atIndex: charIndex + 1)
                        selectedRange = NSMakeRange(charIndex + 3, 0)
                    }
                    
                    hideCaret = true
                } else {
                    self.textSelected = false
                    let area = NSMakeRange(charIndex, 1)
                    selectedRange = area
                    if let _ = textStorage.attribute(NSBackgroundColorAttributeName, atIndex: charIndex, effectiveRange: nil) {
                        textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                    } else {
                        textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                        textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                    }
                }
            }*/
            
            
            // Set Last Selected Token Ranges (Both old and new)
            if !fieldEditor.lastSelectedTokenPosition.selected {
                fieldEditor.lastSelectedTokenPosition.selected = true
                fieldEditor.lastSelectedTokenPosition.oldRange = oldRange
            }
            
            if newRange.location < fieldEditor.lastSelectedTokenPosition.oldRange.location {
                fieldEditor.lastSelectedTokenPosition.direction = .Left
            } else {
                fieldEditor.lastSelectedTokenPosition.direction = .Right
            }
            
            fieldEditor.insertionPointColor = NSColor.whiteColor()
            fieldEditor.lastSelectedTokenPosition.newRange = selectedRange
            fieldEditor.setSelectedRange(selectedRange)
            //TODO: rename this flag to something meaningful
            fieldEditor.mouseWasDragged = true
            self.textSelectedAll = false
            self.textSelected = false
            
        }
    }
}

extension RSTokenField {
    // Respond to delegate methods here
    func shouldAddToken(token: String, atTokenIndex index:Int) -> Bool {
        return true
    }
    
    func textView (textView: RSTokenTextView, didChangeTokens tokens: Array<RSTokenItemType>) {
        self.tokenArray = tokens
    }
    
    func textView(aTextView: NSTextView, menuForToken string: String, atIndex index:Int) -> NSMenu? {
        if ((self.delegate?.respondsToSelector("tokenField:menuForToken:atIndex:")) != nil) {
            let tokenFieldDelegate = self.delegate as! RSTokenFieldDelegate
            return tokenFieldDelegate.tokenField(self, menuForToken: string, atIndex: index)
        }
        return nil
    }
}
