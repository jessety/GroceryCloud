//
//  GroceryListManager.swift
//  GroceryCloud
//
//  Created by Jesse T Youngblood on 2/26/17.
//  Copyright © 2017 Jesse T Youngblood. All rights reserved.
//

import Foundation

protocol GroceryListManagerDelegate {
    /// Executed every time the list has changed
    func listUpdated(_ items: [GroceryItem])
}

/// A class dedicated to managing a list of groceries
class GroceryListManager: GroceryListDocumentDelegate {
    
    var delegate: GroceryListManagerDelegate?
    
    /// Set to true for console messages
    var verbose = true
    
    /// The file manager
    fileprivate let fileManager = FileManager.default
    
    /// The document to read/write from/to
    fileprivate var document: GroceryListDocument?
    
    /// The filename to serialize from/to
    fileprivate let filename = "list.plist"
    
    /// If the app launches and iCloud is enabled but there isn't a save file, use this query to discover if it actually exists
    fileprivate var restoreQuery: NSMetadataQuery?
    
    /// A reference to the callback sent to the restore function, called after restore metadata query completes.
    fileprivate var restoreCallback: ((Bool, [GroceryItem]?) -> Void)? = nil
    
    /// Print a message to the console, if .verbose is true
    ///
    /// - Parameter message: The message to display
    fileprivate func debug(_ message: String) {
        
        guard verbose else {
            return
        }
        
        print("GroceryListManager:", message)
    }
    
    /// The grocery list. If set and the list has changed, re-serialize the document.
    var items: [GroceryItem] {
        
        get {
            
            guard let document = document, let items = document.items else {
                return [GroceryItem]()
            }
            
            return items
        }
        
        set {
            setItems(newValue, completion: nil)
        }
    }
    
    /// Returns either a local file URL, or an ubiquitous URL if iCloud is enabled
    fileprivate var documentURL: URL {
        
        if _documentURL != nil {
            return _documentURL!
        }
        
        // Check if we have iCloud access. If so, use it!
        var ubiquityURL = fileManager.url(forUbiquityContainerIdentifier: nil)
        
        if ubiquityURL != nil {
            
            iCloud = true
            
            ubiquityURL = ubiquityURL!.appendingPathComponent("Documents/\(filename)")
            
            //debug("Using iCloud!")
            debug("Using ubiquitous iCloud file URL: \(ubiquityURL!)")
            
            _documentURL = ubiquityURL
            return ubiquityURL!
        }
        
        let directoryPaths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        
        let url = directoryPaths[0].appendingPathComponent(filename)
        
        //debug("Using local file!")
        debug("Using local URL: \(url)")
        
        _documentURL = url
        return url
    }
    
    /// Cached values from the documentURL getter function
    fileprivate var _documentURL: URL?
    
    /// Whether iCloud is currently enabled
    fileprivate var iCloud = false
    
    // MARK: - serialization
    
    
    /// Restore the grocery list data from disk
    ///
    /// - Parameter completion: Executed after the list has been restored
    func restore(_ completion: ((Bool, [GroceryItem]?) -> Void)?) {
        
        document = GroceryListDocument(fileURL: documentURL)
        
        // If this file is in iCloud, start syncing it now.
        if fileManager.isUbiquitousItem(at: documentURL) {
            
            do {
                try fileManager.startDownloadingUbiquitousItem(at: documentURL)
            } catch let error {
                debug("Could not start syncing iCloud file: \(error)")
            }
        }
        
        if fileManager.fileExists(atPath: documentURL.path) {
            
            // If the file exists, open it!
            debug("The save file exists, opening it..")
            
            document!.open(completionHandler: {(success: Bool) -> Void in
                
                if success {
                    self.debug("Successfully restored data from existing file!")
                } else {
                    self.debug("Could not restore data efrom existing file.")
                }
                
                completion?(success, self.document!.items)
                
                self.document!.delegate = self
            })
            
        } else {
            
            // If the file doesn't exist, we have to determine whether it is located in the user's iCloud shared storage or not
            
            if iCloud {
                
                // The file does NOT exist, but it is located in iCloud Drive. 
                // This might mean that it does in fact exist, but needs to be synced down first. 
                // Create a NSMetadataQuery to search iCloud for this file. When the query completes, we'll know definitively whether the file exists or not.
                
                // If we have a callback, save it and execute it after the query completes.
                
                debug("The save file doesn't exist, but it's saved in iCloud. Running a metadata query to determine if we just need to wait for it to download or not..")
                
                restoreCallback = completion
                
                restoreQuery = NSMetadataQuery()
                
                restoreQuery!.predicate = NSPredicate(format: "%K like '\(filename)'", NSMetadataItemFSNameKey)
                restoreQuery!.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
                
                NotificationCenter.default.addObserver(self, selector: #selector(GroceryListManager.restoreQueryFinished), name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: restoreQuery!)
                
                restoreQuery!.start()
                
            } else {
                
                debug("The save file doesn't exist, and iCloud is not enabled. Creating it!")
                
                // If this document is local but doesn't exist yet, create one.
                
                document!.save(to: documentURL, for: .forCreating, completionHandler: {(success: Bool) -> Void in
                    
                    if success {
                        self.debug("Successfully created new local save file!")
                    } else {
                        self.debug("Failed to create new local save file.!")
                    }
                    
                    completion?(success, self.document!.items)
                    
                    self.document!.delegate = self
                })
                
            }
        }
    }
    
    /// Executed when the restoration metadataquery has completed. Called only if the save file is located in iCloud, but does not yet exist.
    ///
    /// - Parameter notification: The query completion notification
    @objc func restoreQueryFinished(notification: NSNotification) {
        
        // Stop the query. We don't need it anymore.
        
        let query: NSMetadataQuery = notification.object as! NSMetadataQuery
        query.disableUpdates()
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        
        query.stop()
        
        // Now, we know definitively if we have a save file or not
        
        if query.resultCount == 1 {
            
            debug("The restoration metadata query has completed, and we have a save file now! Opening it..")
            
            // We have a save file!
            
            document!.open(completionHandler: {(success: Bool) -> Void in
                
                if success {
                   self.debug("Successfully restored data from iCloud file!")
                } else {
                    self.debug("Failed to restore data from iCloud file.")
                }
                
                self.restoreCallback?(success, self.document!.items)
                self.restoreCallback = nil
                
                self.document!.delegate = self
            })
            
        } else {
            
            debug("The restoration metadata query has completed, but there still isn't a save file. Creating one..")
            
            // The file does not yet exist. Make one!
            
            document!.save(to: documentURL, for: .forCreating, completionHandler: {(success: Bool) -> Void in
                
                if success {
                    self.debug("Successfully created new iCloud save file!")
                } else {
                    self.debug("Failed to create new iCloud save file.")
                }
                
                self.restoreCallback?(success, self.document!.items)
                self.restoreCallback = nil
                
                self.document!.delegate = self
            })
            
        }
    }
    
    /// Serialize the grocery list
    ///
    /// - Parameter completion: Executed upon success or failure of document serialization
    func save(_ completion: ((Bool) -> Void)?) {
        
        document?.save(to: documentURL, for: .forOverwriting, completionHandler: {(success: Bool) -> Void in
            
            if success {
                self.debug("Successfully serialized the list!")
            } else {
                self.debug("Failed to serialize the list.")
            }
            
            completion?(success)
        })
    }
    
    // MARK: - Convenience manipulation functions
    
    /// Add a grocery item, and save the new list
    ///
    /// - Parameters:
    ///   - item: The grocery item to add
    ///   - completion: Executed after the item is added, and the document has been serialized successfully
    func add(_ item: GroceryItem, completion: @escaping (Bool) -> Void) {
        
        guard let document = document else {
            completion(false)
            return
        }
        
        guard var items: [GroceryItem] = document.items else {
            completion(false)
            return
        }
        
        // If this event is already in the 'saved' list, remove it
        
        if let index = items.index(of: item) {
            
            items.remove(at: index)
        }
        
        items.append(item)
        
        document.items = items
        
        save { (success) in
            completion(success)
        }
    }

    /// Remove a grocery item, and save the list
    ///
    /// - Parameters:
    ///   - item: The grocery item to remove
    ///   - completion: Executed after the item is removed, and the document has been serialized successfully
    func remove(_ item: GroceryItem, completion: @escaping (Bool) -> Void) {
        
        guard let document = document else {
            completion(false)
            return
        }
        
        guard var items: [GroceryItem] = document.items else {
            completion(false)
            return
        }
        
        if let index = items.index(of: item) {
            
            items.remove(at: index)
        }
        
        document.items = items
        
        save { (success) in
            completion(success)
        }
    }
    
    /// Replace the existing grocery list
    ///
    /// - Parameters:
    ///   - newItems: The new list of grocer items
    ///   - completion: Executed after the list was replaced, and the document has been serialized successfully
    func setItems(_ newItems: [GroceryItem], completion: ((Bool) -> Void)?) {
        
        guard let document = document else {
            return
        }
        
        // Either the existing list of items is nil, or the lists are different
        guard document.items == nil || newItems != document.items! else {
            return
        }
        
        document.items = newItems
        
        self.save { (success) in
            
            completion?(success)
        }
    }
    
    // MARK: - Document delegation
    
    /// As defined in GroceryListDocumentDelegate. Called when the document's data has been reloaded
    ///
    /// - Parameter items: The new list of items
    func listUpdated(_ items: [GroceryItem]) {
        
        // The document's load:fromContents:ofType: function was just called!
        // This means that the document was re-loaded from disk
        
        debug("Document re-loaded, pushing updated list to delegate!")
        
        self.delegate?.listUpdated(self.document!.items!)
    }
}
