//
//  SimpleTaskListViewModel.swift
//  ToDoList
//
//  Created by Илья Лысенко on 05.08.2025.
//

import Foundation
import CoreData

@MainActor
class SimpleTaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let repo = TaskRepository()

    func initialLoad() {
        isLoading = true
        repo.loadInitialIfNeeded { [weak self] error in
            self?.isLoading = false
            if let error = error {
                self?.errorMessage = error.localizedDescription
            }
            self?.reload()
        }
    }

    func reload() {
        do {
            tasks = try repo.fetchAll(search: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(task: Task) {
        repo.toggleCompleted(task: task)
        reload()
    }

    func delete(task: Task) {
        repo.delete(task: task)
        reload()
    }

    func add(title: String, detail: String) {
        repo.add(title: title, detail: detail)
        reload()
    }
    
    func update(task: Task, title: String, detail: String, comment: String?, completed: Bool) {
        repo.update(task: task, title: title, detail: detail, comment: comment, completed: completed) { [weak self] in
            self?.reload()
        }
    }
    
    func fetchAndSaveFromAPI() {
        isLoading = true
        APIClient().fetchTodos { result in
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let todos):
                    for todo in todos {
                        self.repo.add(title: todo.todo, detail: "", completed: todo.completed)
                    }
                    self.reload()
                case .failure(let error):
                    self.errorMessage = "Ошибка API: \(error.localizedDescription)"
                }
            }
        }
    }

}
