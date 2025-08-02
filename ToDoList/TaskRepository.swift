//
//  TaskRepository.swift
//  ToDoList
//
//  Created by Илья Лысенко on 02.08.2025.
//

import CoreData

class TaskRepository {
    private let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    // Проверка: есть ли уже сохранённые задачи
    func hasTasks() throws -> Bool {
        let req: NSFetchRequest<Task> = Task.fetchRequest()
        req.fetchLimit = 1
        let count = try container.viewContext.count(for: req)
        return count > 0
    }

    // Первичная загрузка: если пусто — подтянуть и сохранить
    func loadInitialIfNeeded(completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                if try self.hasTasks() {
                    DispatchQueue.main.async { completion(nil) }
                    return
                }

                APIClient().fetchTodos { result in
                    switch result {
                    case .success(let todos):
                        let bg = self.container.newBackgroundContext()
                        bg.perform {
                            for t in todos {
                                let task = Task(context: bg)
                                task.id = Int64(t.id)
                                task.title = t.todo
                                task.detail = ""
                                task.createdAt = Date()
                                task.completed = t.completed
                            }
                            do {
                                try bg.save()
                                DispatchQueue.main.async { completion(nil) }
                            } catch {
                                DispatchQueue.main.async { completion(error) }
                            }
                        }
                    case .failure(let error):
                        DispatchQueue.main.async { completion(error) }
                    }
                }
            } catch {
                DispatchQueue.main.async { completion(error) }
            }
        }
    }

    func fetchAll(search: String? = nil) throws -> [Task] {
        let req: NSFetchRequest<Task> = Task.fetchRequest()
        if let s = search, !s.isEmpty {
            req.predicate = NSPredicate(format: "title CONTAINS[cd] %@ OR detail CONTAINS[cd] %@", s, s)
        }
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        return try container.viewContext.fetch(req)
    }

    func toggleCompleted(task: Task) {
        let bg = container.newBackgroundContext()
        bg.perform {
            if let t = try? bg.existingObject(with: task.objectID) as? Task {
                t.completed.toggle()
                try? bg.save()
            }
        }
    }

    func delete(task: Task) {
        let bg = container.newBackgroundContext()
        bg.perform {
            if let t = try? bg.existingObject(with: task.objectID) {
                bg.delete(t)
                try? bg.save()
            }
        }
    }

    func add(title: String, detail: String) {
        let bg = container.newBackgroundContext()
        bg.perform {
            let task = Task(context: bg)
            task.id = Int64(Date().timeIntervalSince1970)
            task.title = title
            task.detail = detail
            task.createdAt = Date()
            task.completed = false
            try? bg.save()
        }
    }
}
