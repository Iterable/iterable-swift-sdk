//
//  Created by Tapash Majumder on 7/20/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import CoreData
import Foundation

enum PersistenceConst {
    static let dataModelFileName = "IterableDataModel"
    enum EntityName {
        static let task = "IterableTaskManagedObject"
    }
}

@available(iOS 10.0, *)
class PersistentContainer: NSPersistentContainer {
    static let shared: PersistentContainer = {
        let container = PersistentContainer(name: PersistenceConst.dataModelFileName)
        container.loadPersistentStores { desc, error in
            if let error = error {
                fatalError("Unresolved error \(error)")
            }
            
            ITBInfo("Successfully loaded persistent store at: \(desc.url?.description ?? "nil")")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        
        return container
    }()
    
    override func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = super.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        return backgroundContext
    }
}

@available(iOS 10.0, *)
struct CoreDataPersistenceContextProvider: IterablePersistenceContextProvider {
    init(dateProvider: DateProviderProtocol = SystemDateProvider()) {
        self.dateProvider = dateProvider
    }
    
    func newBackgroundContext() -> IterablePersistenceContext {
        CoreDataPersistenceContext(managedObjectContext: PersistentContainer.shared.newBackgroundContext(), dateProvider: dateProvider)
    }
    
    func mainQueueContext() -> IterablePersistenceContext {
        CoreDataPersistenceContext(managedObjectContext: PersistentContainer.shared.viewContext, dateProvider: dateProvider)
    }
    
    private let dateProvider: DateProviderProtocol
}

@available(iOS 10.0, *)
struct CoreDataPersistenceContext: IterablePersistenceContext {
    init(managedObjectContext: NSManagedObjectContext, dateProvider: DateProviderProtocol) {
        self.managedObjectContext = managedObjectContext
        self.dateProvider = dateProvider
    }
    
    func create(task: IterableTask) throws -> IterableTask {
        guard let taskManagedObject = createTaskManagedObject() else {
            throw IterableDBError.general("Could not create task managed object")
        }
        
        PersistenceHelper.copy(from: task, to: taskManagedObject)
        taskManagedObject.created = dateProvider.currentDate
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func update(task: IterableTask) throws -> IterableTask {
        guard let taskManagedObject = try findTaskManagedObject(id: task.id) else {
            throw IterableDBError.general("Could not find task to update")
        }
        
        PersistenceHelper.copy(from: task, to: taskManagedObject)
        taskManagedObject.modified = dateProvider.currentDate
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func delete(task: IterableTask) throws {
        try deleteTask(withId: task.id)
    }
    
    func createTask(id: String, processor: String) throws -> IterableTask {
        guard let taskManagedObject = createTaskManagedObject() else {
            throw IterableDBError.general("Could not create task managed object")
        }
        taskManagedObject.id = id
        taskManagedObject.created = dateProvider.currentDate
        taskManagedObject.processor = processor
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func findTask(withId id: String) throws -> IterableTask? {
        guard let taskManagedObject = try findTaskManagedObject(id: id) else {
            return nil
        }
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func deleteTask(withId id: String) throws {
        guard let taskManagedObject = try findTaskManagedObject(id: id) else {
            return
        }
        managedObjectContext.delete(taskManagedObject)
    }
    
    func save() throws {
        try managedObjectContext.save()
    }
    
    private let managedObjectContext: NSManagedObjectContext
    private let dateProvider: DateProviderProtocol
    
    private func findTaskManagedObject(id: String) throws -> IterableTaskManagedObject? {
        try CoreDataUtil.findEntitiyByColumn(context: managedObjectContext, entity: PersistenceConst.EntityName.task, columnName: "id", columnValue: id)
    }
    
    private func createTaskManagedObject() -> IterableTaskManagedObject? {
        CoreDataUtil.create(context: managedObjectContext, entity: PersistenceConst.EntityName.task) as? IterableTaskManagedObject
    }
}
