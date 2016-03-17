
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
    
    private var _tokenArray: [RSTokenItem]? = nil
    
    var tokenArray: [RSTokenItem]!  {
        get {
            return self._tokenArray ?? [RSTokenItem]()
        }
        
        set {
            if let _ = self._tokenArray {
                if (self._tokenArray! != newValue) {
                    let appendedAttributeString = NSMutableAttributedString()
                    
                    let whiteSpace = NSMutableAttributedString(string: " ")
                    
                    for token in newValue.reverse() {
                        var topLevelObjects: NSArray?
                        NSBundle.mainBundle().loadNibNamed("RSTokenView", owner:self, topLevelObjects:&topLevelObjects)
                        
                        var view: RSTokenView!
                        
                        for o in topLevelObjects! {
                            if o is RSTokenView {
                                view = o as! RSTokenView
                                view!.tokenItem = token
                            }
                        }
                        
                        let attachment = RSTextAttachment.init(withTokenView: view)
                        
                        let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                        attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                        attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                        
                        appendedAttributeString.appendAttributedString(whiteSpace)
                        appendedAttributeString.appendAttributedString(attributeString)
                        
                        appendedAttributeString.appendAttributedString(whiteSpace)
                    }
                    
                    self.attributedStringValue = appendedAttributeString
                    
                    if let cell = self.cell {
                        self.fieldEditor = cell.fieldEditorForView(self) as? RSTokenTextView
                    }
                    
                    if let textStorage = self.fieldEditor!.textStorage {
                        textStorage.setAttributedString(appendedAttributeString)
                    }
                }
            }
            
            self._tokenArray = newValue
        }
    }
    
    override var objectValue: AnyObject? {
        set {
            self.tokenArray = newValue as? [RSTokenItem]
        }
        
        get {
            return self.tokenArray
        }
    }
    
    //MARK: Public Methods
    
    func replaceToken(withType type: String, tokenTitle title: String, atIndex index: Int) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        
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
                    
                    self.tokenArray[index/3] = v.tokenView.tokenItem
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
    
    func setToken(selected: Bool, atIndex index: Int) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let v = value as? RSTextAttachment {
                if range.location == index {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    v.tokenView.selected = selected
                    
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
    
    /*func textView(textView: NSTextView, willChangeSelectionFromCharacterRange oldSelectedCharRange: NSRange, toCharacterRange newSelectedCharRange: NSRange) -> NSRange {
        return NSMakeRange(NSNotFound, 0)
    }*/
    
    func textViewDidChangeSelection(notification: NSNotification) {
        if let fieldEditor = self.fieldEditor, textStorage = fieldEditor.textStorage, userInfo = notification.userInfo, oldRange: NSRange = userInfo["NSOldSelectedCharacterRange"] as? NSRange, newRange: NSRange = fieldEditor.selectedRange {
            /*let selectedText = (fieldEditor.string! as NSString).substringWithRange(fieldEditor.selectedRange)
            NSLog("selected: %@ - %@", selectedText, NSStringFromRange(fieldEditor.selectedRange))*/
            
            if newRange.length == 0 {
                return
            } else if oldRange.location == newRange.location && oldRange.length == newRange.length {
                return
            } else if self.textSelected {
                self.textSelected = false
                return
            }
            
            let charIndex = newRange.location
            var hideCaret = false
            
            if textStorage.tokenStringAtIndex(charIndex) != nil {
                self.textSelected = true
                self.setToken(true, atIndex: charIndex)
                hideCaret = true
                if newRange.location < oldRange.location {
                    fieldEditor.setSelectedRange(NSMakeRange(charIndex - 1, 0))
                } else {
                    fieldEditor.setSelectedRange(NSMakeRange(charIndex + 2, 0))
                }
            } else {
                let string = textStorage.string as NSString
                let unichar = string.characterAtIndex(charIndex)
                let unicharString = Character(UnicodeScalar(unichar))
                if unicharString == " " && ((charIndex > 0 && textStorage.tokenStringAtIndex(charIndex - 1) != nil) || (charIndex < textStorage.length && textStorage.tokenStringAtIndex(charIndex + 1) != nil)) {
                    self.textSelected = true
                    
                    if newRange.location < oldRange.location {
                        self.setToken(true, atIndex: charIndex - 1)
                        fieldEditor.setSelectedRange(NSMakeRange(charIndex - 2, 0))
                    } else {
                        self.setToken(true, atIndex: charIndex + 1)
                        fieldEditor.setSelectedRange(NSMakeRange(charIndex + 3, 0))
                    }
                    
                    hideCaret = true
                } else {
                    self.textSelected = false
                    let area = NSMakeRange(charIndex, 1)
                    textStorage.removeAttribute(NSBackgroundColorAttributeName, range: area)
                    textStorage.addAttribute(NSBackgroundColorAttributeName, value: NSColor.controlHighlightColor(), range: area)
                }
            }
            
            if newRange.location < oldRange.location {
                fieldEditor.lastSelectedTokenPosition.direction = .Left
            } else {
                fieldEditor.lastSelectedTokenPosition.direction = .Right
            }
            
            if !fieldEditor.lastSelectedTokenPosition.selected {
                fieldEditor.lastSelectedTokenPosition.selected = true
                fieldEditor.lastSelectedTokenPosition.oldRange = oldRange
            }
            
            fieldEditor.lastSelectedTokenPosition.newRange = newRange
            
            if hideCaret {
                fieldEditor.insertionPointColor = NSColor.whiteColor()
            } else {
                fieldEditor.insertionPointColor = NSColor.blackColor()
            }
            
            //TODO: rename this flag to something meaningful
            fieldEditor.mouseWasDragged = true
        
        }
    }
}

extension RSTokenField {
    // Respond to delegate methods here
    func shouldAddToken(token: String, atTokenIndex index:Int) -> Bool {
        return true
    }
    
    func textView (textView: RSTokenTextView, didChangeTokens tokens: Array<RSTokenItem>) {
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
