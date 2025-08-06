//
//  ToDoListTests.swift
//  ToDoListTests
//
//  Created by Илья Лысенко on 06.08.2025.
//


import XCTest
@testable import ToDoList

final class SimpleTaskListViewModelTests: XCTestCase {
    func testAddTask() async throws {
        let viewModel = await SimpleTaskListViewModel()
        await viewModel.repo.clearAll()

        await viewModel.add(title: "Test Task", detail: "Test Detail")
        let tasks = await viewModel.tasks

        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.title, "Test Task")
    }

    func testDeleteTask() async throws {
        let viewModel = await SimpleTaskListViewModel()
        await viewModel.repo.clearAll()

        await viewModel.add(title: "To be deleted", detail: "")
        let task = await viewModel.tasks.first!

        await viewModel.delete(task: task)
        let tasksAfter = await viewModel.tasks

        XCTAssertTrue(tasksAfter.isEmpty)
    }
}




