//
//  RSTokenItem.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

@objc class RSTokenItem: NSObject, NSCoding, RSTokenItemType {
    var tokenType: String!
    var tokenTitle: String!
    
    var stem: String! = ""
    
    init(type: String, title: String) {
        self.tokenType = type
        self.tokenTitle = title
        super.init()
    }
    
    convenience required init?(coder aDecoder: NSCoder) {
        guard let type = aDecoder.decodeObjectForKey("tokenType"), let title = aDecoder.decodeObjectForKey("tokenTitle")  else {
            return nil
        }
        
        self.init(type: type as! String, title: title as! String)
        self.stem = aDecoder.decodeObjectForKey("stem") as! String
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(self.tokenType, forKey: "tokenType")
        aCoder.encodeObject(self.tokenTitle, forKey: "tokenTitle")
        aCoder.encodeObject(self.stem, forKey: "stem")
    }
}

