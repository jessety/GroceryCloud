//
//  GroceryItemCell.swift
//  GroceryCloud
//
//  Created by Jesse T Youngblood on 3/2/17.
//  Copyright © 2017 Jesse T Youngblood. All rights reserved.
//

import UIKit

class GroceryItemCell: UITableViewCell {
    
    /// Displays either a checkmark, or an empty circle
    fileprivate var checkboxView: UIImageView
    
    /// Set this cell's corresponding grocery item.
    var item: GroceryItem? {
        
        didSet {
            
            guard item != nil else {
                
                textLabel?.text = ""
                checkboxView.image = UIImage(named: "unchecked")
                return
            }
            
            textLabel?.text = item?.name
            
            if item?.completed == true {
                
                checkboxView.image = UIImage(named: "checked")
                
            } else {
                
                checkboxView.image = UIImage(named: "unchecked")
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let frame = self.bounds
        
        checkboxView.frame = CGRect(x: (frame.width - 40), y: ((frame.height - 30) / 2), width: 30, height: 30)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        checkboxView = UIImageView()
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(checkboxView)
        
        selectionStyle = .none
        accessoryView = checkboxView
    }
    
    convenience init(item: GroceryItem) {
        
        self.init(style: .subtitle, reuseIdentifier: "event")
        
        self.item = item
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    // MARK: - NSCoder
    
    required init?(coder: NSCoder) {
        
        checkboxView = UIImageView()
        
        super.init(coder: coder)
        
        contentView.addSubview(checkboxView)
        
        selectionStyle = .none
        accessoryView = checkboxView
        
        self.item = coder.decodeObject(forKey: "item") as? GroceryItem
    }
    
    func encodeWithCoder(coder: NSCoder) {
        
        coder.encode(self.item, forKey: "item")
    }
}
