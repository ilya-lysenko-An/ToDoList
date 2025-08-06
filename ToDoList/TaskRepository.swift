//
//  TaskRepository.swift
//  ToDoList
//
//  Created by Илья Лысенко on 02.08.2025.
//

import Foundation
import CoreData

class TaskRepository {
    private let viewContext = PersistenceController.shared.container.viewContext

    func fetchAll(search: String) throws -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        if !search.isEmpty {
            request.predicate = NSPredicate(format: "title CONTAINS[cd] %@", search)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Task.createdAt, ascending: false)]
        return try viewContext.fetch(request)
    }

    func toggleCompleted(task: Task) {
        task.completed.toggle()
        save()
    }

    func delete(task: Task) {
        viewContext.delete(task)
        save()
    }

    func add(title: String, detail: String, completed: Bool = false) {
        let newTask = Task(context: viewContext)
        newTask.title = title
        newTask.detail = detail
        newTask.completed = completed
        newTask.createdAt = Date()
        save()
    }

   func update(task: Task, title: String, detail: String, comment: String?, completed: Bool, completion: @escaping () -> Void) {
        task.title = title
        task.detail = detail
        task.comment = comment
        task.completed = completed
        save()
        completion()
    }

    private func save() {
        do {
            try viewContext.save()
        } catch {
            print("Ошибка при сохранении: \(error)")
        }
    }

    func loadInitialIfNeeded(completion: @escaping (Error?) -> Void) {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        do {
            let existing = try viewContext.fetch(request)
            if existing.isEmpty {
                // Если нет задач — грузим с API
                APIClient().fetchTodos { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let todos):
                            for todo in todos {
                                self.add(title: todo.todo, detail: "", completed: todo.completed)
                            }
                            completion(nil)
                        case .failure(let error):
                            completion(error)
                        }
                    }
                }
            } else {
                completion(nil)
            }
        } catch {
            completion(error)
        }
    }
    
    func clearAll() {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = Task.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print("Ошибка при очистке базы: \(error)")
        }
    }
}

