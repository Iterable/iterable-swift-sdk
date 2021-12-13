//
//  Copyright © 2020 Iterable. All rights reserved.
//

import CoreData
import Foundation

enum PersistenceConst {
    static let dataModelFileName = "IterableDataModel"
    static let dataModelExtension = "momd"

    enum Entity {
        enum Task {
            static let name = "IterableTaskManagedObject"
            
            enum Column {
                static let id = "id"
                static let scheduledAt = "scheduledAt"
            }
        }
    }
}

class PersistentContainer: NSPersistentContainer {
    static var shared: PersistentContainer?
    
    static func initialize(fromBundle bundle: Bundle) -> PersistentContainer? {
        if shared == nil {
            shared = create(fromBundle: bundle)
        }
        return shared
    }
    
    override func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = super.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        return backgroundContext
    }

    private static func create(fromBundle bundle: Bundle) -> PersistentContainer? {
        guard let managedObjectModel = createManagedObjectModel(fromBundle: bundle) else {
            ITBError("Could not initialize managed object model")
            return nil
        }
        let container = PersistentContainer(name: PersistenceConst.dataModelFileName, managedObjectModel: managedObjectModel)
        container.loadPersistentStores { desc, error in
            if let error = error {
                ITBError("Unresolved error when creating PersistentContainer: \(error)")
            }
            
            ITBInfo("Successfully loaded persistent store at: \(desc.url?.description ?? "nil")")
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        
        return container
    }
    
    private static func createManagedObjectModel(fromBundle bundle: Bundle) -> NSManagedObjectModel? {
        guard let url = managedObjectUrl(fromBundle: bundle) else {
            ITBError("Could not find \(PersistenceConst.dataModelFileName).\(PersistenceConst.dataModelExtension) in bundle")
            return nil
        }
        ITBInfo("DB Bundle url: \(url)")
        return NSManagedObjectModel(contentsOf: url)
    }
    
    private static func managedObjectUrl(fromBundle bundle: Bundle) -> URL? {
        ResourceHelper.url(forResource: PersistenceConst.dataModelFileName,
                           withExtension: PersistenceConst.dataModelExtension,
                           fromBundle: bundle)
    }
}

struct CoreDataPersistenceContextProvider: IterablePersistenceContextProvider {
    init?(dateProvider: DateProviderProtocol = SystemDateProvider(),
          fromBundle bundle: Bundle = Bundle.main) {
        guard let persistentContainer = PersistentContainer.initialize(fromBundle: bundle) else {
            return nil
        }
        self.persistentContainer = persistentContainer
        self.dateProvider = dateProvider
    }
    
    func newBackgroundContext() -> IterablePersistenceContext {
        return CoreDataPersistenceContext(managedObjectContext: persistentContainer.newBackgroundContext(), dateProvider: dateProvider)
    }
    
    func mainQueueContext() -> IterablePersistenceContext {
        return CoreDataPersistenceContext(managedObjectContext: persistentContainer.viewContext, dateProvider: dateProvider)
    }
    
    private let persistentContainer: PersistentContainer
    private let dateProvider: DateProviderProtocol
}

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
        taskManagedObject.createdAt = dateProvider.currentDate
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func update(task: IterableTask) throws -> IterableTask {
        guard let taskManagedObject = try findTaskManagedObject(id: task.id) else {
            throw IterableDBError.general("Could not find task to update")
        }
        
        PersistenceHelper.copy(from: task, to: taskManagedObject)
        taskManagedObject.modifiedAt = dateProvider.currentDate
        return PersistenceHelper.task(from: taskManagedObject)
    }
    
    func delete(task: IterableTask) throws {
        try deleteTask(withId: task.id)
    }

    func nextTask() throws -> IterableTask? {
        let taskManagedObjects: [IterableTaskManagedObject] = try CoreDataUtil.findSortedEntities(context: managedObjectContext,
                                                                                                  entity: PersistenceConst.Entity.Task.name,
                                                                                                  column: PersistenceConst.Entity.Task.Column.scheduledAt,
                                                                                                  ascending: true,
                                                                                                  limit: 1)
        return taskManagedObjects.first.map(PersistenceHelper.task(from:))
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
    
    func findAllTasks() throws -> [IterableTask] {
        let taskManagedObjects: [IterableTaskManagedObject] = try CoreDataUtil.findAll(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name)
        
        return taskManagedObjects.map(PersistenceHelper.task(from:))
    }
    
    func deleteAllTasks() throws {
        let taskManagedObjects: [IterableTaskManagedObject] = try CoreDataUtil.findAll(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name)
        taskManagedObjects.forEach { managedObjectContext.delete($0) }
    }
    
    func countTasks() throws -> Int {
        return try CoreDataUtil.count(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name)
    }
    
    func save() throws {
        try managedObjectContext.save()
    }
    
    func perform(_ block: @escaping () -> Void) {
        managedObjectContext.perform(block)
    }
    
    func performAndWait(_ block: () -> Void) {
        managedObjectContext.performAndWait(block)
    }
    
    private let managedObjectContext: NSManagedObjectContext
    private let dateProvider: DateProviderProtocol
    
    private func findTaskManagedObject(id: String) throws -> IterableTaskManagedObject? {
        try CoreDataUtil.findEntitiyByColumn(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name, columnName: PersistenceConst.Entity.Task.Column.id, columnValue: id)
    }
    
    private func createTaskManagedObject() -> IterableTaskManagedObject? {
        CoreDataUtil.create(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name)
    }
}
