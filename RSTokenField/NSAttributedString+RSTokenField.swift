//
//  NSAttributedString+RSTokenField.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Foundation
import Cocoa

extension NSAttributedString {
    
    func countOfRSTokensInRange(aRange: NSRange) -> Int {
        if aRange.location == 0 {
            return 0
        }
        
        var count = 0
        var curRange = NSMakeRange(aRange.location + aRange.length - 1, 0)
        
        while curRange.location != NSNotFound && curRange.location >= aRange.location {
            if curRange.location < self.length {
                let attribute = self.attribute(NSAttachmentAttributeName, atIndex: curRange.location, effectiveRange: &curRange)
                if attribute is RSTextAttachment {
                    count++
                }
            }
            curRange = NSMakeRange(curRange.location > 0 ? curRange.location - 1: NSNotFound, 0)
        }
        return count
    }
    
    func tokenStringAtIndex(index: Int) -> String? {
        if index < self.length {
            let attribute = self.attribute(NSAttachmentAttributeName, atIndex: index, effectiveRange: nil)
            if attribute is RSTextAttachment {
                return (attribute as! RSTextAttachment).tokenView.tokenItem.tokenTitle
            }
        }
        return nil
    }
    
    func isTokenAtIndexSelected(index: Int) -> Bool {
        if index < self.length {
            let attribute = self.attribute(NSAttachmentAttributeName, atIndex: index, effectiveRange: nil)
            if attribute is RSTextAttachment {
                return (attribute as! RSTextAttachment).tokenView.selected
            }
        }
        return false
    }
}