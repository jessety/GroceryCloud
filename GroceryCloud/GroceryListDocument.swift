//
//  GroceryListDocument.swift
//  GroceryCloud
//
//  Created by Jesse T Youngblood on 2/26/17.
//  Copyright © 2017 Jesse T Youngblood. All rights reserved.
//

import UIKit

protocol GroceryListDocumentDelegate {
    // Executed every time the list has changed
    func listUpdated(_ items: [GroceryItem])
}

class GroceryListDocument: UIDocument {

    /// The list of grocery items
    var items: [GroceryItem]? = []
    
    /// The delegate
    var delegate: GroceryListDocumentDelegate?
    
    //MARK: - UIDocument
    
    override func contents(forType typeName: String) throws -> Any {
        
        guard let events = items else {
            return NSKeyedArchiver.archivedData(withRootObject: [String]())
        }
        
        return NSKeyedArchiver.archivedData(withRootObject: events)
    }
    
    override func load(fromContents contents: Any, ofType typeName: String?) throws {
        
        guard let data = contents as? Data else {
            return
        }
        
        items = NSKeyedUnarchiver.unarchiveObject(with: data) as? [GroceryItem]
        
        delegate?.listUpdated(items!)
    }
}
