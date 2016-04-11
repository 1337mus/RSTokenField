//
//  RSTokenFieldCell.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/29/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class RSTokenFieldCell: NSTextFieldCell, NSTextViewDelegate {
    
    override func fieldEditorForView(aControlView: NSView) -> NSTextView? {
        struct Static {
            static var onceToken: dispatch_once_t = 0
            static var tokenTextView: RSTokenTextView? = nil
        }
        dispatch_once(&Static.onceToken) {
            Static.tokenTextView = RSTokenTextView()
            Static.tokenTextView?.fieldEditor = true
            NSNotificationCenter.defaultCenter().addObserver(Static.tokenTextView!, selector: "didRedo:", name: NSUndoManagerDidRedoChangeNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(Static.tokenTextView!, selector: "didUndo:", name: NSUndoManagerDidUndoChangeNotification, object: nil)
        }
        
        return Static.tokenTextView
    }
    
    override func selectWithFrame(aRect: NSRect, inView controlView: NSView, editor textObj: NSText, delegate anObject: AnyObject?, start selStart: Int, length selLength: Int) {
        super.selectWithFrame(aRect, inView: controlView, editor: textObj, delegate: anObject, start: selStart, length: selLength)
        let textView = textObj as! RSTokenTextView
        textObj.selectedRange = NSMakeRange(textView.textStorage!.length, 0)
    }
    
    override func setUpFieldEditorAttributes(textObj: NSText) -> NSText {
        let result = super.setUpFieldEditorAttributes(textObj) as! NSTextView
        result.textStorage?.font = NSFont.systemFontOfSize(12)
        return result
    }
}
