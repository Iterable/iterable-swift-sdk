//
//  Created by Tapash Majumder on 7/21/20.
//  Copyright © 2020 Iterable. All rights reserved.
//
//  This file should contain general CoreData helper methods.
//  This should not be dependent on Iterable classes.

import CoreData
import Foundation

struct CoreDataUtil {
    static func create<T: NSFetchRequestResult>(context: NSManagedObjectContext, entity: String) -> T? {
        NSEntityDescription.insertNewObject(forEntityName: entity, into: context) as? T
    }
    
    static func findEntitiyByColumn<T: NSFetchRequestResult>(context: NSManagedObjectContext,
                                                             entity: String,
                                                             columnName: String,
                                                             columnValue: Any) throws -> T? {
        try findEntitiesByColumns(context: context, entity: entity, columns: [columnName: columnValue]).first
    }
    
    static func findAll<T: NSFetchRequestResult>(context: NSManagedObjectContext, entity: String) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: entity)
        return try context.fetch(request)
    }
    
    static func findEntitiesByColumns<T: NSFetchRequestResult>(context: NSManagedObjectContext, entity: String, columns: [String: Any]) throws -> [T] {
        let request = NSFetchRequest<T>(entityName: entity)
        request.predicate = createColumnsPredicate(columns: columns)
        return try context.fetch(request)
    }
    
    private static func createColumnsPredicate(columns: [String: Any]) -> NSPredicate {
        var subPredicates = [NSPredicate]()
        for (columnName, columnValue) in columns {
            subPredicates.append(createColumnPredicate(columnName: columnName, columnValue: columnValue))
        }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: subPredicates)
    }
    
    private static func createColumnPredicate(columnName: String, columnValue: Any) -> NSPredicate {
        if let stringValue = columnValue as? String {
            return NSPredicate(format: "%K ==[c] %@", columnName, stringValue)
        } else if let intValue = columnValue as? Int {
            return NSPredicate(format: "%K == %d", columnName, intValue)
        } else if let boolValue = columnValue as? Bool {
            return NSPredicate(format: "%K == %@", columnName, NSNumber(value: boolValue))
        } else {
            fatalError("unsuppored value: \(columnValue)")
        }
    }
}
