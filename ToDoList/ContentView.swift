//
//  ContentView.swift
//  ToDoList
//
//  Created by Илья Лысенко on 01.08.2025.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var vm = SimpleTaskListViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if vm.isLoading {
                    ProgressView("Загрузка...")
                        .padding()
                }
                if let error = vm.errorMessage {
                    Text("Ошибка: \(error)").foregroundColor(.red)
                }
                TextField("Поиск", text: $vm.searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onChange(of: vm.searchText) { _ in
                        vm.reload()
                    }

                List {
                    ForEach(vm.tasks, id: \.objectID) { task in
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
                                    vm.toggle(task: task)
                                }
                        }
                    }
                    .onDelete { idx in
                        for i in idx {
                            let t = vm.tasks[i]
                            vm.delete(task: t)
                        }
                    }
                }
            }
            .navigationTitle("Задачи")
            .toolbar {
                Button(action: {
                    vm.add(title: "Новая задача", detail: "Описание")
                }) {
                    Image(systemName: "plus")
                }
            }
            .onAppear {
                vm.initialLoad()
            }
        }
    }
}

private let itemFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
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
            if let e = error {
                self?.errorMessage = e.localizedDescription
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
}

