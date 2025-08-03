//
//  ContentView.swift
//  ToDoList
//
//  Created by Илья Лысенко on 01.08.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var taskListViewModel = SimpleTaskListViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if taskListViewModel.isLoading {
                    ProgressView("Загрузка...")
                        .padding()
                }
                if let error = taskListViewModel.errorMessage {
                    Text("Ошибка: \(error)").foregroundColor(.red)
                }
                TextField("Поиск", text: $taskListViewModel.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: taskListViewModel.searchText) { _ in
                        taskListViewModel.reload()
                    }

                List {
                    ForEach(taskListViewModel.tasks, id: \.objectID) { task in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(task.title ?? "Без названия").bold()
                                if let detail = task.detail, !detail.isEmpty {
                                    Text(detail).font(.caption)
                                }
                                if let date = task.createdAt {
                                    Text(date, formatter: itemFormatter)
                                        .font(.caption2)
                                }
                            }
                            Spacer()
                            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
                                .onTapGesture {
                                    taskListViewModel.toggle(task: task)
                                }
                        }
                    }
                    .onDelete { idx in
                        for i in idx {
                            let t = taskListViewModel.tasks[i]
                            taskListViewModel.delete(task: t)
                        }
                    }
                }
            }
            .navigationTitle("Задачи")
            .toolbar {
                Button(action: {
                    taskListViewModel.add(title: "Новая задача", detail: "Описание")
                }) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                taskListViewModel.initialLoad()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let taskDateFormatter = DateFormatter()
    taskDateFormatter.dateStyle = .short
    taskDateFormatter.timeStyle = .short
    return taskDateFormatter
}()

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

}

