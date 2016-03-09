//
//  NSImage+RSTokenField.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 3/7/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

extension NSImage {
    func tintedImageWithColor(color:NSColor) -> NSImage {
        let size        = self.size
        let imageBounds = NSMakeRect(0, 0, size.width, size.height)
        let copiedImage = self.copy() as! NSImage
        
        copiedImage.lockFocus()
        color.set()
        NSRectFillUsingOperation(imageBounds, .CompositeSourceAtop)
        copiedImage.unlockFocus()
        
        return copiedImage
    }
}
