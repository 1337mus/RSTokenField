//
//  RSTokenView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenView: NSView {

    private struct Constants {
        static let titleLeftPadding: CGFloat = 5.0
        static let titleInset: CGFloat = 2.0
        static let cornerRadius: CGFloat = 3.0
    }
    
    @IBOutlet weak var type: NSTextField!
    @IBOutlet weak var title: NSTextField!
    @IBOutlet weak var imageView: NSImageView!
    
    private var selectedBackgroundColor: NSColor = NSColor.controlHighlightColor()
    private var selectedTypeColor: NSColor = NSColor(white: 218.0/255.0, alpha: 1)
    
    var tokenItem: RSTokenItem! {
        didSet {
            self.type.stringValue = tokenItem.tokenType.uppercaseString
            self.type.sizeToFit()
            
            self.title.stringValue = tokenItem.tokenTitle
            self.title.sizeToFit()
            
            self.type.backgroundColor = NSColor.clearColor()
            self.title.backgroundColor = NSColor.clearColor()
            
            self.type.frame = NSMakeRect(2, self.frame.origin.y + 1, self.type.frame.size.width, self.type.frame.size.height)
            self.imageView.frame = NSMakeRect(self.type.frame.size.width + self.type.frame.origin.x, self.type.frame.origin.y - 1, self.imageView.frame.size.width, self.imageView.frame.size.height)
            self.title.frame = NSMakeRect(self.imageView.frame.size.width + self.imageView.frame.origin.x + Constants.titleLeftPadding, self.frame.origin.y + 1, self.title.frame.size.width + Constants.titleInset, self.title.frame.size.height)
            self.frame = NSMakeRect(0, self.frame.origin.y, self.imageView.frame.size.width + self.type.frame.size.width + self.title.frame.size.width + Constants.titleLeftPadding, self.frame.size.height)
            
            self.needsDisplay = true
        }
    }
    
    var selected: Bool = false {
        willSet {
            var textColor = NSColor.blackColor()
            var backgroundColor = NSColor.controlHighlightColor()
            var titleBackgroundColor = NSColor(white: 218.0/255.0, alpha: 1)
            
            if newValue == true {
                textColor = NSColor.whiteColor()
                backgroundColor = NSColor.disabledControlTextColor()
                titleBackgroundColor = backgroundColor
            }
            
            self.type.textColor = textColor
            self.title.textColor = textColor
            let image = self.imageView.image?.tintedImageWithColor(textColor)
            self.imageView.image = image
            
            self.selectedBackgroundColor = backgroundColor
            self.selectedTypeColor = titleBackgroundColor
            self.needsDisplay = true
        }
    }
    
    var typeSelected: Bool = false {
        willSet {
            // Induce color change only when the whole token is not selected
            if !selected {
                var textColor = NSColor.blackColor()
                var backgroundColor = NSColor(white: 218.0/255.0, alpha: 1)
                
                if newValue == true {
                    textColor = NSColor.whiteColor()
                    backgroundColor = NSColor.disabledControlTextColor()
                }
                
                self.type.textColor = textColor
                let image = self.imageView.image?.tintedImageWithColor(textColor)
                self.imageView.image = image
                
                self.selectedTypeColor = backgroundColor
                
                 self.needsDisplay = true
            }
        }
    }
    
    override func drawRect(dirtyRect: NSRect) {
        let rect = NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, self.type.frame.width + self.imageView.frame.width, dirtyRect.height)
        
        // Draw the title with one rounded rect and one edged rect
        var path = NSBezierPath(roundedRect: NSMakeRect(rect.width + Constants.titleLeftPadding/2 + Constants.titleInset, dirtyRect.origin.y, (dirtyRect.width - rect.width)/2, dirtyRect.height), xRadius: 0, yRadius: 0)
        var anotherpath = NSBezierPath(roundedRect: NSMakeRect(rect.width + (dirtyRect.width - rect.width)/2 - Constants.titleLeftPadding/2, dirtyRect.origin.y, (dirtyRect.width - rect.width)/2 + Constants.titleLeftPadding/2, dirtyRect.height), xRadius: Constants.cornerRadius, yRadius: Constants.cornerRadius)
        path.appendBezierPath(anotherpath)
        self.selectedBackgroundColor.set()
        path.fill()
        
        // Draw the Type with one rounded rect and one edged rect
        path = NSBezierPath(roundedRect: NSMakeRect(dirtyRect.origin.x, dirtyRect.origin.y, rect.width/2, dirtyRect.height), xRadius: Constants.cornerRadius, yRadius: Constants.cornerRadius)
        anotherpath = NSBezierPath(roundedRect: NSMakeRect(rect.width/2 - Constants.titleInset, dirtyRect.origin.y, rect.width/2 + Constants.titleLeftPadding, dirtyRect.height), xRadius: 0, yRadius: 0)
        path.appendBezierPath(anotherpath)
        self.selectedTypeColor.set()
        path.fill()
    }
    
    func imageRepresentation() -> NSImage {
        return NSImage.init(data: self.dataWithPDFInsideRect(self.bounds))!
    }
}
