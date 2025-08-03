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
                        let background = self.container.newBackgroundContext()
                        background.perform {
                            for t in todos {
                                let task = Task(context: background)
                                task.id = Int64(t.id)
                                task.title = t.todo
                                task.detail = ""
                                task.createdAt = Date()
                                task.completed = t.completed
                            }
                            do {
                                try background.save()
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
        let background = container.newBackgroundContext()
        background.perform {
            if let t = try? background.existingObject(with: task.objectID) as? Task {
                t.completed.toggle()
                try? background.save()
            }
        }
    }

    func delete(task: Task) {
        let background = container.newBackgroundContext()
        background.perform {
            if let t = try? background.existingObject(with: task.objectID) {
                background.delete(t)
                try? background.save()
            }
        }
    }

    func add(title: String, detail: String) {
        let background = container.newBackgroundContext()
        background.perform {
            let task = Task(context: background)
            task.id = Int64(Date().timeIntervalSince1970)
            task.title = title
            task.detail = detail
            task.createdAt = Date()
            task.completed = false
            try? background.save()
        }
    }
    
    func update(task: Task, title: String, detail: String, comment: String?, completed: Bool, completion: @escaping () -> Void) {
        let background = container.newBackgroundContext()
        background.perform {
            if let t = try? background.existingObject(with: task.objectID) as? Task {
                t.title = title
                t.detail = detail
                t.comment = comment
                t.completed = completed
                // сохраняем дату изменения, если нужно (можно не менять createdAt)
                do {
                    try background.save()
                } catch {
                    // логирование, но продолжаем
                    print("Update save error: \(error)")
                }
            }
            DispatchQueue.main.async {
                completion()
            }
        }
    }

}
