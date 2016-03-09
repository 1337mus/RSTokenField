//
//  RSTokenItemSection.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 3/6/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

protocol RSTokenItemType {
    
}

class RSTokenItemSection: Hashable, RSTokenItemType {
    var sectionName: String!
    
    init(name: String) {
        self.sectionName = name
    }
    
    var hashValue: Int {
        get {
            return self.sectionName.hashValue;
        }
    }
}

func ==(lhs: RSTokenItemSection, rhs: RSTokenItemSection) -> Bool {
        return lhs.sectionName == rhs.sectionName
}

