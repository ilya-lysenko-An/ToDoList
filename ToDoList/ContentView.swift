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
    @State private var selectedTaskForEditing: Task?
    @State private var selectedTask: Task?

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
                        Button {
                            selectedTaskForEditing = task
                        } label: {
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
                                    .foregroundColor(task.completed ? .green : .gray)
                            }
                        }
                        .buttonStyle(PlainButtonStyle())
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
            .sheet(item: $selectedTaskForEditing) { taskToEdit in
                TaskEditSheetView(
                    task: taskToEdit
                ) { updatedTask, newTitle, newDetail, newComment, newCompleted in
                    taskListViewModel.update(
                        task: updatedTask,
                        title: newTitle,
                        detail: newDetail,
                        comment: newComment,
                        completed: newCompleted
                    )
                    selectedTaskForEditing = nil 
                }
            }
        }
        .hideKeyboardOnTap()
    }
}

private let itemFormatter: DateFormatter = {
    let taskDateFormatter = DateFormatter()
    taskDateFormatter.dateStyle = .short
    taskDateFormatter.timeStyle = .short
    return taskDateFormatter
}()

extension View {
    func hideKeyboardOnTap() -> some View {
        self.gesture(
            TapGesture()
                .onEnded { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
        )
    }
}


