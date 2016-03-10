//
//  RSTokenView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenView: NSView {

    @IBOutlet weak var type: NSTextField!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    var tokenItem: RSTokenItem! {
        didSet {
            self.type.stringValue = tokenItem.tokenType
            self.type.sizeToFit()
            
            self.title.stringValue = tokenItem.tokenTitle
            self.title.sizeToFit()
            
            self.imageView.frame = NSMakeRect(self.type.frame.size.width + self.type.frame.origin.x, self.imageView.frame.origin.y, self.imageView.frame.size.width, self.imageView.frame.size.height)
            self.title.frame = NSMakeRect(self.imageView.frame.size.width + self.imageView.frame.origin.x, self.title.frame.origin.y, self.title.frame.size.width, self.title.frame.size.height)
            self.frame = NSMakeRect(self.frame.origin.x, self.frame.origin.y, self.imageView.frame.size.width + self.type.frame.size.width + self.title.frame.size.width, self.frame.size.height)
        }
    }
    
    var selected: Bool! = false {
        willSet {
            var textColor = NSColor.blackColor()
            var backgroundColor = NSColor.controlHighlightColor()
            if newValue == true {
                textColor = NSColor.whiteColor()
                backgroundColor = NSColor.disabledControlTextColor()
            }
            
            self.type.textColor = textColor
            self.title.textColor = textColor
            
            self.type.backgroundColor = backgroundColor
            self.title.backgroundColor = backgroundColor
        }
    }
    
    var typeSelected: Bool! = false {
        willSet {
            var textColor = NSColor.blackColor()
            var backgroundColor = NSColor.controlHighlightColor()
            if newValue == true {
                textColor = NSColor.whiteColor()
                backgroundColor = NSColor.disabledControlTextColor()
            }
            
            self.type.textColor = textColor
            self.type.backgroundColor = backgroundColor
        }
    }
    
    override func resizeSubviewsWithOldSize(oldSize: NSSize) {
        super.resizeSubviewsWithOldSize(oldSize)
        
    }
    
    override func drawRect(dirtyRect: NSRect) {
        NSColor.whiteColor().set()
        NSRectFill(self.bounds)
    }
    
    func imageRepresentation() -> NSImage {
        return NSImage.init(data: self.dataWithPDFInsideRect(self.bounds))!
    }
}
