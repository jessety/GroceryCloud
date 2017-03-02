//
//  GroceryItem.swift
//  GroceryCloud
//
//  Created by Jesse T Youngblood on 2/28/17.
//  Copyright © 2017 Jesse T Youngblood. All rights reserved.
//

import Foundation

// A grocery item 🍏🧀🍞🥚
class GroceryItem: NSObject, NSSecureCoding {
    
    enum GroceryCategory: Int {
        case produce = 0
        case bakery = 1
        case meat = 2
        case dairy = 3
        case other = 4
    }
    
    /// The name of the grocery item
    var name: String
    
    /// The category this grocery item falls into. Optional.
    var category: GroceryCategory?

    /// Initializes a new GroceryItem with the specified name
    ///
    /// - Parameter name: The name of the grocery item
    init(_ name: String) {
        self.name = name
    }
    
    // MARK: - NSCoding / NSSecureCoding
    
    /// Required as per NSSecureCoding
    public static var supportsSecureCoding: Bool = true
    
    /// Encode this object with a NSCoder
    ///
    /// - Parameter aCoder: An archiver object
    open func encode(with aCoder: NSCoder) {
        
        aCoder.encode(name, forKey: "name")
        
        if category != nil {
            aCoder.encode(self.category!.rawValue, forKey: "category")
        }
    }
    
    /// Returns an GroceryItem initialized from data in a given unarchiver.
    ///
    /// - Parameter coder: The coder to initialize from
    required public init(coder: NSCoder) {
        
        name = coder.decodeObject(of: NSString.self, forKey: "name") as! String
        
        category = GroceryCategory.init(rawValue: coder.decodeInteger(forKey: "category"))
    }
    
    /// Implementation of the Equatable protocol
    ///
    /// - Parameters:
    ///   - left: A GroceryItem
    ///   - right: Another GroceryItem
    /// - Returns: Equality
    static func == (left: GroceryItem, right: GroceryItem) -> Bool {
        
        if left.name != right.name {
            return false
        }
        
        if left.category != right.category {
            return false
        }
        
        return true
    }
}
