//
//  RSTokenField.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc protocol RSTokenFieldDelegate : NSTextFieldDelegate {
    optional func tokenField(tokenField: RSTokenField, completionsForSubstring: String) -> [String]
    optional func tokenField(tokenField: RSTokenField, didChangeTokens tokens: [RSTokenItem])
    optional func tokenField(tokenField: RSTokenField, willChangeTokens tokens: [RSTokenItem])
    optional func tokenField(tokenField: RSTokenField, shouldAddToken token: String, atIndex index: Int) -> Bool
    optional func tokenField(tokenField: RSTokenField, menuForToken string: String, atIndex index: Int) -> NSMenu
}

class RSTokenField: NSTextField, NSTextViewDelegate {

    private var _tokenArray: [RSTokenItem]? = nil
    
    var tokenArray: [RSTokenItem]!  {
        get {
            return self._tokenArray
        }
        
        set {
            if let _ = self._tokenArray {
                if (self._tokenArray! != newValue) {
                    let appendedAttributeString = NSMutableAttributedString()
                    
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
                        
                        appendedAttributeString.appendAttributedString(attributeString)
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
    
    //MARK: NSTextViewDelegate Methods
    
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
        return nil
    }
}
