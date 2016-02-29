//
//  RSTokenItem.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenItem: NSObject {
    var tokenType: RSTokenType!
    var tokenTitle: String!
    
    init(type: RSTokenType, title: String) {
        self.tokenType = type
        self.tokenTitle = title
    }
}
