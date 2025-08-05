//
//  TaskEditSheetView.swift
//  ToDoList
//
//  Created by Илья Лысенко on 03.08.2025.
//

import SwiftUI

struct TaskEditSheetView: View {
    @Environment(\.dismiss) var dismiss

    @ObservedObject var task: Task
    @State private var title: String
    @State private var detail: String
    @State private var comment: String
    @State private var completed: Bool

    var onSave: (Task, String, String, String?, Bool) -> Void

    init(task: Task, onSave: @escaping (Task, String, String, String?, Bool) -> Void) {
        self.task = task
        _title = State(initialValue: task.title ?? "")
        _detail = State(initialValue: task.detail ?? "")
        _comment = State(initialValue: task.comment ?? "")
        _completed = State(initialValue: task.completed)
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 16) {
            Capsule()
                .frame(width: 40, height: 5)
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 8)

            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Название", text: $title)
                        .font(.title2)
                        .bold()
                    TextField("Описание", text: $detail)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button {
                    completed.toggle()
                } label: {
                    Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                        .font(.title)
                        .foregroundColor(completed ? .green : .gray)
                }
                .accessibilityLabel("Метка выполнено")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Комментарий")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $comment)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.bottom, 4)
            }

            Spacer()

            HStack {
                Button("Отмена") {
                    dismiss()
                }
                .buttonStyle(.bordered)

                Spacer()

                Button("Сохранить") {
                    onSave(task, title, detail, comment.isEmpty ? nil : comment, completed)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding()
        .presentationDetents([.fraction(0.45), .medium])
    }

}
