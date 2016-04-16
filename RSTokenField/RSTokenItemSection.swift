//
//  RSTokenItemSection.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 3/6/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

protocol RSTokenItemType: NSObjectProtocol {
    
}

class RSTokenItemSection: NSObject, RSTokenItemType {
    var sectionName: String!
    
    init(name: String) {
        self.sectionName = name
    }
}

