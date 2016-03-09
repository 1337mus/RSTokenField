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

    private var _tokenArray: [RSTokenItem]? = nil
    
    var tokenArray: [RSTokenItem]!  {
        get {
            return self._tokenArray
        }
        
        set {
            if let _ = self._tokenArray {
                if (self._tokenArray! != newValue) {
                    let appendedAttributeString = NSMutableAttributedString()
                    
                    var i = false
                    let whiteSpace = NSMutableAttributedString(string: " ")
                    
                    for token in newValue.reverse() {
                        var topLevelObjects: NSArray?
                        NSBundle.mainBundle().loadNibNamed("RSTokenView",
                            owner:self, topLevelObjects:&topLevelObjects)
                        
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
                        
                        if !i {
                            i = true
                            //appendedAttributeString.appendAttributedString(whiteSpace)
                        }
                        appendedAttributeString.appendAttributedString(whiteSpace)
                        appendedAttributeString.appendAttributedString(attributeString)
                        
                        appendedAttributeString.appendAttributedString(whiteSpace)
                    }
                    
                    self.attributedStringValue = appendedAttributeString
                    
                    let fieldEditor = self.cell?.fieldEditorForView(self) as! RSTokenTextView
                    fieldEditor.textStorage?.setAttributedString(appendedAttributeString)
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
                    
                    v.tokenView.tokenItem = RSTokenItem(type: type, title: title)
                    self.tokenArray[index/3] = v.tokenView.tokenItem
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                    stop.initialize(true)
                }
            }
        }
        
        self.attributedStringValue = mutableAttrString
        
        let fieldEditor = self.cell?.fieldEditorForView(self) as! RSTokenTextView
        fieldEditor.textStorage?.setAttributedString(mutableAttrString)
        
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
                    
                } else {
                    mutableAttrString.removeAttribute(NSAttachmentAttributeName, range: range)
                    v.tokenView.selected = !selected
                    let attachment = RSTextAttachment.init(withTokenView: v.tokenView)
                    
                    mutableAttrString.addAttribute(NSAttachmentAttributeName, value: attachment, range: range)
                }
                
            }
        }
        
        self.attributedStringValue = mutableAttrString
        
        let fieldEditor = self.cell?.fieldEditorForView(self) as! RSTokenTextView
        fieldEditor.textStorage?.setAttributedString(mutableAttrString)
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
