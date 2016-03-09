//
//  ViewController.swift
//  RSTokenField
//
//  Created by Rajath Bhagavathi on 2/28/16.
//  Copyright © 2016 KittyKat. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    var menuItemContext = [String:String]()
    
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

    func action(sender: NSMenuItem) {
        if let menuItem = sender.representedObject, let item = menuItem as? RSMenuItemObject {
            self.tokenField.replaceToken(withType: item.tokenType, tokenTitle: item.tokenTitle, atIndex: item.tokenIndex)
        }
    }

}

extension ViewController: RSTokenFieldDelegate {
    func tokenField(tokenField: RSTokenField, var completionsForSubstring subString: String) -> [RSTokenItemType] {
        let tokenCompletionSections = ["Fruits", "Nuts", "Flowers", "Seeds"]
        let tokenCompletionArray =  ["Apple", "Banana", "Pears", "Star Fruit", "Dragon Fruit", "Mango", "Pineapple", "Coconut", "Lychee", "Blackberry", "Papaya", "Blueberry", "Raspberry",
        "Orange", "Sweet Lime", "Cashew", "Almond", "Grapes", "Peach", "Custard Apple", "Jack fruit", "Chickoo", "Random fruit", "The fruit fox couldn't reach", "My Mom",
        "My Dad", "Anal fruit", "Plum"]
        
        var dataSource = [AnyObject]()
        
        let divisor: Int = tokenCompletionArray.count / tokenCompletionSections.count
        for var i = 0; i < tokenCompletionSections.count; i++ {
            for var j = divisor * i; j < divisor * (i + 1) ; j++ {
                if j % divisor == 0 {
                    dataSource.append(RSTokenItemSection.init(name: tokenCompletionSections[i]))
                }
                dataSource.append(RSTokenItem.init(type: tokenCompletionSections[i], title: tokenCompletionArray[j]))
            }
        }
        
        subString = subString.stringByTrimmingCharactersInSet(
            NSCharacterSet.whitespaceAndNewlineCharacterSet()
        )
        
        var alphaNumericRange = subString.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet())
        var alphaSubstring = ""
        var searchFullString = false
        
        if let _ = alphaNumericRange {
            alphaSubstring = subString.substringFromIndex((alphaNumericRange?.startIndex)!)
        } else {
            alphaSubstring = subString
            searchFullString = true
        }
        
        var matches = [String]()
        var matchesDictionary = [RSTokenItemSection : [RSTokenItem]]()
        
        for data in dataSource {
            if data is RSTokenItemSection { continue }
            
            let candidate = (data as! RSTokenItem).tokenTitle
            var found = false
            for tokenItem in tokenField.tokenArray {
                if tokenItem.tokenTitle == candidate {
                    found = true
                }
            }
            if found { continue }
            
            alphaNumericRange = subString.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet())
            if let _ = alphaNumericRange {
                let alphaKeyword = searchFullString ? candidate : candidate.substringFromIndex(alphaNumericRange!.startIndex)
                let subStringRange = alphaKeyword.rangeOfString(alphaSubstring, options: [NSStringCompareOptions.CaseInsensitiveSearch, NSStringCompareOptions.DiacriticInsensitiveSearch], range: nil, locale: nil)
                if let _ = subStringRange {
                    if let _ = matchesDictionary[RSTokenItemSection.init(name: data.tokenType)] {
                        matchesDictionary[RSTokenItemSection.init(name: data.tokenType)]?.append(data as! RSTokenItem)
                    } else {
                        matchesDictionary[RSTokenItemSection.init(name: data.tokenType)] = [data as! RSTokenItem]
                    }
                    matches.append(candidate)
                }
            }
        }
        
        var result = [RSTokenItemType]()
        
        for (key,val) in matchesDictionary {
            result.append(key)
            for v in val {
                result.append(v)
            }
        }
        
        return result
    }
    
    func tokenField(tokenField: RSTokenField, didChangeTokens tokens: [RSTokenItem]) {
        
    }
    
    func tokenField(tokenField: RSTokenField, willChangeTokens tokens: [RSTokenItem]) {
        
    }
    
    func tokenField(tokenField: RSTokenField, shouldAddToken token: String, atIndex index: Int) -> Bool {
        return true
    }
    
    func tokenField(tokenField: RSTokenField, menuForToken string: String, atIndex index: Int) -> NSMenu {
        let test = NSMenu()
        let itemNames = ["A", "B", "Entire Message"]
        for name in itemNames {
            let item = NSMenuItem.init(title: name, action: "action:", keyEquivalent: "")
            item.target = self
            item.representedObject = RSMenuItemObject(type: name, title: string, index: index)
            test.addItem(item)
        }
        return test
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

class RSMenuItemObject: NSObject {
    var tokenType: String!
    var tokenTitle: String!
    var tokenIndex: Int!
    
    init(type: String, title: String, index: Int) {
        self.tokenType = type
        self.tokenTitle = title
        self.tokenIndex = index
    }
}
