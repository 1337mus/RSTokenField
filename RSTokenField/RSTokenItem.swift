//
//  RSTokenItem.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenItem: NSObject, RSTokenItemType {
    var tokenType: String!
    var tokenTitle: String!
    
    init(type: String, title: String) {
        self.tokenType = type
        self.tokenTitle = title
    }
}
