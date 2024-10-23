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

let sharedManagedObjectModel: NSManagedObjectModel? = {
    let firstBundleURL: URL? = [Bundle.main, Bundle(for: PersistentContainer.self)].lazy.compactMap { bundle in
        ResourceHelper.url(
            forResource: PersistenceConst.dataModelFileName,
            withExtension: PersistenceConst.dataModelExtension,
            fromBundle: bundle
        )
    }.first

    guard let url = firstBundleURL else {
        ITBError("Could not find \(PersistenceConst.dataModelFileName).\(PersistenceConst.dataModelExtension) in bundle")
        return nil
    }
    ITBInfo("DB Bundle url: \(url)")
    return NSManagedObjectModel(contentsOf: url)
}()

final class PersistentContainer: NSPersistentContainer, @unchecked Sendable {

    override func newBackgroundContext() -> NSManagedObjectContext {
        let backgroundContext = super.newBackgroundContext()
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
        return backgroundContext
    }

    init() {
        let name = PersistenceConst.dataModelFileName
        if let managedObjectModel = sharedManagedObjectModel {
            super.init(name: name, managedObjectModel: managedObjectModel)
        } else {
            super.init(name: name)
        }
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergePolicy(merge: NSMergePolicyType.mergeByPropertyStoreTrumpMergePolicyType)
    }
}

final class CoreDataPersistenceContextProvider: IterablePersistenceContextProvider {
    init(
        dateProvider: DateProviderProtocol = SystemDateProvider(),
        persistentContainer: NSPersistentContainer = PersistentContainer()
    ) {
        self.persistentContainer = persistentContainer
        self.dateProvider = dateProvider
    }

    func newBackgroundContext() -> IterablePersistenceContext {
        if !isStoreLoaded {
            isStoreLoaded = loadStore(into: persistentContainer)
        }
        return CoreDataPersistenceContext(managedObjectContext: persistentContainer.newBackgroundContext(), dateProvider: dateProvider)
    }

    func mainQueueContext() -> IterablePersistenceContext {
        if !isStoreLoaded {
            isStoreLoaded = loadStore(into: persistentContainer)
        }
        return CoreDataPersistenceContext(managedObjectContext: persistentContainer.viewContext, dateProvider: dateProvider)
    }

    private let persistentContainer: NSPersistentContainer
    private let dateProvider: DateProviderProtocol
    private var isStoreLoaded = false

    /// Loads the persistent container synchronously so we can easily capture loading errors.
    private func loadStore(into container: NSPersistentContainer) -> Bool {
        if let descriptor = container.persistentStoreDescriptions.first {
            descriptor.shouldAddStoreAsynchronously = false
        }

        // This closure runs synchronously because of the settings above
        var loadError: (any Error)?
        container.loadPersistentStores { _, error in
            loadError = error
        }

        if let error = loadError {
            ITBError("Failed to load Iterable's store. \(error.localizedDescription)")
            return false
        }
        return true
    }
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
        let taskManagedObjects: [IterableTaskManagedObject] = try CoreDataUtil.findSortedEntities(
            context: managedObjectContext,
            entity: PersistenceConst.Entity.Task.name,
            column: PersistenceConst.Entity.Task.Column.scheduledAt,
            ascending: true,
            limit: 1
        )
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
        taskManagedObjects.forEach {
            if !$0.isDeleted {
                managedObjectContext.delete($0)
            } else {
                ITBDebug("task already deleted")
            }
        }
    }

    func countTasks() throws -> Int {
        try CoreDataUtil.count(context: managedObjectContext, entity: PersistenceConst.Entity.Task.name)
    }

    func save() throws {
        // Guard against Objective-C exceptions which cannot be caught in Swift.
        guard
            let coordinator = managedObjectContext.persistentStoreCoordinator,
            !coordinator.persistentStores.isEmpty
        else {
            throw NSError(domain: NSCocoaErrorDomain, code: NSPersistentStoreSaveError)
        }
        try managedObjectContext.save()
    }

    func perform(_ block: @escaping () -> Void) {
        managedObjectContext.perform(block)
    }

    func performAndWait(_ block: () -> Void) {
        managedObjectContext.performAndWait(block)
    }

    func performAndWait<T>(_ block: () throws -> T) throws -> T {
        try managedObjectContext.performAndWait(block)
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
