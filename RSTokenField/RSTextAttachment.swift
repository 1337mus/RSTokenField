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
    
    func refreshTokenView() {
        let cell = RSTextAttachmentCell(imageCell:tokenView.imageRepresentation())
        self.attachmentCell = cell
    }
}
