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

        // Можно подставить пару тестовых задач
        for i in 1...5 {
            let task = Task(context: context)
            task.id = Int64(i)
            task.title = "Пример \(i)"
            task.detail = "Описание задачи \(i)"
            task.createdAt = Date()
            task.completed = (i % 2 == 0)
        }
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
            let desc = NSPersistentStoreDescription()
            desc.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [desc]
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
        let bg = container.newBackgroundContext()
        bg.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return bg
    }
}

