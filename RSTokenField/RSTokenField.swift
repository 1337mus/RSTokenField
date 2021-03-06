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
            self._tokenArray = newValue
            
            if let cell = self.cell {
                self.fieldEditor = cell.fieldEditorForView(self) as? RSTokenTextView
            }
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
                    
                    let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                    attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                    attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                    
                    self.fieldEditor?.textStorage?.replaceCharactersInRange(range, withAttributedString: attributeString)
                    stop.initialize(true)
                }
            }
        }
    }
    
    func setToken(typeOnly type: Bool, selected: Bool, atIndex index: Int) {
        let mutableAttrString = self.attributedStringValue.mutableCopy() as! NSMutableAttributedString
        mutableAttrString.enumerateAttribute(NSAttachmentAttributeName, inRange: NSMakeRange(0, mutableAttrString.length), options: .LongestEffectiveRangeNotRequired) { (value: AnyObject?, range: NSRange, stop) -> Void in
            if let v = value as? RSTextAttachment {
                if range.location == index {
                    if type {
                        v.tokenView.typeSelected = selected && !v.tokenView.selected
                    } else {
                        v.tokenView.selected = selected
                    }
                    
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                    attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                    attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                    
                    self.fieldEditor?.textStorage?.replaceCharactersInRange(range, withAttributedString: attributeString)
                } else if !type {
                    v.tokenView.selected = !selected
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                    attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                    attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                    
                    self.fieldEditor?.textStorage?.replaceCharactersInRange(range, withAttributedString: attributeString)
                }
                
            }
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
                    v.tokenView.selected = force ? selected : !v.tokenView.selected
                    
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    let attributeString = NSMutableAttributedString.init(attributedString: NSAttributedString.init(attachment: attachment))
                    attributeString.addAttribute(NSAttachmentAttributeName, value: attachment, range: NSMakeRange(0, attributeString.length))
                    attributeString.addAttribute(NSBaselineOffsetAttributeName, value:0, range: NSMakeRange(0, attributeString.length))
                    
                    self.fieldEditor?.textStorage?.replaceCharactersInRange(range, withAttributedString: attributeString)
                    
                    stop.initialize(true)
                }
                
            }
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
    
    func undoManagerForTextView(view: NSTextView) -> NSUndoManager? {
        return self.undoManager
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
