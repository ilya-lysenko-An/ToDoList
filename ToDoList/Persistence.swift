//
//  Persistence.swift
//  ToDoList
//
//  Created by Илья Лысенко on 01.08.2025.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    // Для превью/тестов: in-memory store
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

    // Инициализация: on-disk по умолчанию, или in-memory если нужно
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ToDoList") // имя должно совпадать с .xcdatamodeld
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // Во время разработки можно логировать, но не падать в проде
                fatalError("Unresolved CoreData error: \(error), \(error.userInfo)")
            }
        }
        // Чтобы изменения из background контекстов попадали в viewContext
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // Удобный метод для сохранения контекста (без блокировки)
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

    // Фоновый контекст для мутаций
    func newBackgroundContext() -> NSManagedObjectContext {
        let background = container.newBackgroundContext()
        background.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return background
    }
}

