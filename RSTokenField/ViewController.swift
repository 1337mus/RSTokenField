//
//  ViewController.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var tokenField: OEXTokenField! {
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

