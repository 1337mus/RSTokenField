//
//  RSTokenCompletionTableView.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTokenCompletionTableView: NSTableView {

    func resetWindowFrame() {
        let totalHeight = CGFloat(min(self.numberOfRows, 20)) * (25 + self.intercellSpacing.height)
        var f = self.window?.frame
        let top = NSMaxY(f!)
        let bottom = top - totalHeight
        f = NSMakeRect(NSMinX(f!), bottom, NSWidth(f!), totalHeight)
        self.window?.setFrame(f!, display: true)
    }
    
    override func reloadData() {
        super.reloadData()
        self.resetWindowFrame()
    }
}
