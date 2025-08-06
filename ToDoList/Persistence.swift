//
//  Persistence.swift
//  ToDoList
//
//  Created by Илья Лысенко on 01.08.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        do {
            try context.save()
        } catch {
            print("Preview save error: \(error)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ToDoList")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved CoreData error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func saveContext(context: NSManagedObjectContext? = nil) {
        let ctx = context ?? container.viewContext
        if ctx.hasChanges {
            ctx.perform {
                do {
                    try ctx.save()
                } catch {
                    print("CoreData save error: \(error)")
                }
            }
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        let background = container.newBackgroundContext()
        background.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return background
    }
}

