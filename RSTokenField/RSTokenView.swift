//
//  RSTokenView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenView: NSView {

    @IBOutlet weak var typeButton: NSButton!
    @IBOutlet weak var title: NSTextField!
    
    var tokenItem: RSTokenItem! {
        didSet {
            self.title.stringValue = tokenItem.tokenTitle
            self.typeButton.stringValue = "author"
            self.layoutSubtreeIfNeeded()
        }
    }
    
    override func resizeSubviewsWithOldSize(oldSize: NSSize) {
        super.resizeSubviewsWithOldSize(oldSize)
        self.title.sizeToFit()
        self.typeButton.sizeToFit()
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
    
    func imageRepresentation() -> NSImage {
        return NSImage.init(data: self.dataWithPDFInsideRect(self.bounds))!
    }
}
