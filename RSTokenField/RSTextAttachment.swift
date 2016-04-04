//
//  RSTextAttachment.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTextAttachment: NSTextAttachment {
    
    var tokenView: RSTokenView!
    
    convenience init(withTokenView tokenView: RSTokenView) {
        self.init()
        self.tokenView = tokenView
        let cell = RSTextAttachmentCell(imageCell:tokenView.imageRepresentation())
        self.attachmentCell = cell
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        guard let v = aDecoder.decodeObjectForKey("tokenView") else { return nil }
        self.init(withTokenView:v as! RSTokenView)
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(self.tokenView, forKey: "tokenView")
    }
    
    func refreshTokenView() {
        let cell = RSTextAttachmentCell(imageCell:tokenView.imageRepresentation())
        self.attachmentCell = cell
    }
}
