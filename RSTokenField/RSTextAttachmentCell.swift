//
//  RSTextAttachmentCell.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTextAttachmentCell: NSTextAttachmentCell {

    /*override func cellFrameForTextContainer(textContainer: NSTextContainer, proposedLineFragment lineFrag: NSRect, glyphPosition position: NSPoint, characterIndex charIndex: Int) -> NSRect {
        return self.scaleImageSize(toHeight: lineFrag.height)
    }*/

    /*override func drawWithFrame(cellFrame: NSRect, inView controlView: NSView?) {
        if let img = self.image {
            let rect = NSMakeRect(cellFrame.origin.x , cellFrame.origin.y + 1, cellFrame.size.width, cellFrame.size.height)
            img .drawInRect(rect, fromRect: NSZeroRect, operation: .CompositeSourceOver, fraction: 1.0, respectFlipped: true, hints: nil)
        }
    }*/
    
    func scaleImageSize(toHeight height: CGFloat) -> NSRect {
        var scalingFactor: CGFloat = 1
        let imageSize = self.image?.size
        
        if height < imageSize?.height {
            scalingFactor = height / (imageSize?.height)!
        }
        
        return NSMakeRect(0, 0, (imageSize?.width)! * scalingFactor, (imageSize?.height)! * scalingFactor)
    }
    
    override func wantsToTrackMouse() -> Bool {
        return true
    }
    override func trackMouse(theEvent: NSEvent, inRect cellFrame: NSRect, ofView controlView: NSView?, untilMouseUp flag: Bool) -> Bool {
        return true
    }
    
    override func cellBaselineOffset() -> NSPoint {
        var baseline = super.cellBaselineOffset()
        baseline.y = baseline.y - 4.0
        return baseline
    }
}
