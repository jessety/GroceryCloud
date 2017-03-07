//
//  ViewController.swift
//  GroceryCloud
//
//  Created by Jesse T Youngblood on 2/27/17.
//  Copyright © 2017 Jesse T Youngblood. All rights reserved.
//

import UIKit

class ViewController: UITableViewController, GroceryListManagerDelegate {
    
    let listManager = GroceryListManager()
    
    var addButton: UIBarButtonItem?
    var removeAllButton: UIBarButtonItem?
    
    // MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // By default, the add button will occupy the upper righthand corner. However, in edit mode, a "remove all" button will be displayed instead
        addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(ViewController.add))
        
        removeAllButton = UIBarButtonItem(title: "Remove All", style: .plain, target: self, action: #selector(ViewController.promptToRemoveAll))
        
        self.navigationItem.rightBarButtonItem = addButton

        // The upper lefthand corner will display a button that will kick the table into edit mode, allowing the user to re-arrange their items
        self.navigationItem.leftBarButtonItem = editButtonItem
        editButtonItem.action = #selector(ViewController.toggleEdit)
        
        // Let's not look so basic.
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.barTintColor = UIColor(red: 252.0/255.0, green: 182.0/255.0, blue: 54.0/255.0, alpha: 1.0)
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        UIApplication.shared.statusBarStyle = .lightContent
        
        self.title = "Grocery List"
        
        listManager.delegate = self
        
        // Restore the list of grocery items, either from iCloud or a local file.
        listManager.restore { (success, items) in
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: -
    
    /// Present an input VC and ask the user to type the name of an item to add
    func add() {
        
        let title = "Add Item"
        let message = "Add a grocery item"
        
        let prompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        prompt.addTextField { (textField) in
            
            textField.autocapitalizationType = .sentences;
            textField.autocorrectionType = .yes
        }
        
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        prompt.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            
            let textField = prompt.textFields![0]
            
            guard var input = textField.text else {
                return
            }
            
            input = input.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard input != "" else {
                return
            }
            
            let item = GroceryItem(input)
            
            self.listManager.add(item, completion: { (success) in
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            })
        }))
        
        present(prompt, animated: true, completion: nil)
    }
    
    /// Toggle the tabele's Edit mode
    func toggleEdit() {
        
        if tableView.isEditing {
            
            // If the table view is already in editing mode, switch it back out.
            
            tableView.setEditing(false, animated: true)
            
            editButtonItem.title = "Edit"
            editButtonItem.style = .plain
            
            // Switch the right bar button itom out for the "add" button
            navigationItem.rightBarButtonItem = addButton
            
        } else {
            
            tableView.setEditing(true, animated: true)
            
            editButtonItem.title = "Done"
            editButtonItem.style = .done
            
            // Switch the right bar button item out for a "remote all" button
            navigationItem.rightBarButtonItem = removeAllButton
        }
    }
    
    /// Prompt the user if they would like to remove all items from their grocery list
    func promptToRemoveAll() {
        
        // If edit mode is enabled, they have the option to remove all items. We want to be sure to prompt them first, though.
        
        let title = "Remove All Items"
        let message = "Would you like to remove all items from this list?"
        
        let prompt = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        prompt.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        prompt.addAction(UIAlertAction(title: "Remove", style: .destructive, handler: { (action) in
            
            // Well here we go.
            self.removeAll()
        }))
        
        present(prompt, animated: true, completion: nil)
    }
    
    /// Remove all items from the user's grocery list
    func removeAll() {
        
        let newItems = [GroceryItem]()
        
        listManager.setItems(newItems) { (success) in
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return listManager.items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let identifier = "item"
        
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? GroceryItemCell ?? GroceryItemCell(style: .subtitle, reuseIdentifier: identifier)
        
        cell.item = listManager.items[indexPath.row]
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let item = listManager.items[indexPath.row]
            
            listManager.remove(item, completion: { (success) in
                
                guard success == true else {
                    return
                }
                
                // Delete the row from the data source
                tableView.deleteRows(at: [indexPath], with: .fade)
            })
            
        } else if editingStyle == .insert {
            
            // Not implemented.
            
        }
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        
        var items = listManager.items
        let item = items[sourceIndexPath.row]
        
        items.remove(at: sourceIndexPath.row)
        items.insert(item, at: destinationIndexPath.row)
        
        listManager.items = items
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {

        return true
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        guard let cell = tableView.cellForRow(at: indexPath) as? GroceryItemCell else {
            return
        }
        
        let item = listManager.items[indexPath.row]
        
        item.completed = !item.completed
        
        cell.item = item
        
        // Re-serialize the list
        listManager.save(nil)
    }

 
    // MARK: - GroceryListManagerDelegate

    /// As defined in GroceryListManagerDelegate, called if the list is mutated by something in the background, e.g. the user adds an item from another iCloud enabled device
    ///
    /// - Parameter items: The new list of items
    func listUpdated(_ items: [GroceryItem]) {
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
}
