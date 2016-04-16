//
//  RSTokenPasteboardItem.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 4/2/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

let RSTOKEN_UTI = "com.kittykat.tokenpasteboarditemytype"

class RSTokenPasteboardItem: NSObject, NSCoding, NSPasteboardReading {
    
    var attributedString: NSAttributedString
    
    init(withAttributedString aString: NSAttributedString) {
        self.attributedString = aString
        super.init()
    }
    
    override init() {
        self.attributedString = NSAttributedString.init()
        super.init()
    }
    
    //MARK: NSPasteboardReading Protocol Methods
    static func readableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [RSTOKEN_UTI, NSPasteboardTypeString]
    }
    
    static func readingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardReadingOptions {
        if type == RSTOKEN_UTI {
            return .AsKeyedArchive
        }
        
        return .AsString
    }
    
    
    convenience required init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
        if type == RSTOKEN_UTI {
            if let plistData = propertyList as? NSData, unArchive = NSKeyedUnarchiver(forReadingWithData: plistData).decodeObjectForKey(RSTOKEN_UTI) as? NSAttributedString {
                self.init(withAttributedString: unArchive)
            } else {
                self.init()
                return nil
            }
        } else {
            self.init()
            return nil
        }
    }
    
    //MARK: NSCoding Protocol
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(attributedString, forKey: RSTOKEN_UTI)
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        guard let decoded = aDecoder.decodeObjectForKey(RSTOKEN_UTI) as? NSAttributedString else {
            return nil
        }
        self.init(withAttributedString: decoded)
    }
}

extension RSTokenPasteboardItem: NSPasteboardWriting {
    func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        return [RSTOKEN_UTI, NSPasteboardTypeString]
    }
    
    func pasteboardPropertyListForType(type: String) -> AnyObject? {
        if type == RSTOKEN_UTI {
            return NSKeyedArchiver.archivedDataWithRootObject(self)
        }
        
        if type == NSPasteboardTypeString {
            var string = ""
            //Loop through the attributed string and form a string to paste
            for var i = 0; i < attributedString.length; i++ {
                if let attribute = attributedString.attribute(NSAttachmentAttributeName, atIndex: i, effectiveRange: nil) {
                    if let a = attribute as? RSTextAttachment {
                        string.appendContentsOf(a.tokenView.description)
                    }
                } else {
                    let s = attributedString.string as NSString
                    string.append(Character(UnicodeScalar(s.characterAtIndex(i))))
                }
            }
            
            return string
        }
        
        return nil
    }
}
