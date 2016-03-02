//
//  ViewController.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var tokenField: RSTokenField! {
        didSet {
            tokenField.delegate = self
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

extension ViewController: RSTokenFieldDelegate {
    func tokenField(tokenField: RSTokenField, completionsForSubstring: String) -> [String] {
        return ["Apple", "Banana", "Pears", "Star Fruit", "Dragon Fruit", "Mango", "Pineapple", "Coconut", "Lychee", "Blackberry", "Papaya", "Blueberry", "Raspberry",
        "Orange", "Sweet Lime", "Cashew", "Almond", "Grapes", "Peach", "Custard Apple", "Jack fruit", "Chickoo", "Random fruit", "The fruit fox couldn't reach", "My Mom",
        "My Dad", "Anal fruit"]
    }
}

extension ViewController: OEXTokenFieldDelegate {
    func tokenField(tokenField: OEXTokenField!, attachmentCellForRepresentedObject representedObject: AnyObject!) -> NSTextAttachmentCell! {
        if let tokenFieldCell: OEXTokenFieldCell = tokenField.cell as? OEXTokenFieldCell {
            if let layoutManager = tokenFieldCell.fieldEditorForView(tokenField)?.layoutManager {
                let attachmentCell = OEXTokenAttachmentCell(layoutManager: layoutManager)
                return attachmentCell
            }
        }
        
        return nil
    }
}

