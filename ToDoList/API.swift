//
//  API.swift
//  ToDoList
//
//  Created by Илья Лысенко on 02.08.2025.
//
import Foundation

struct Todo: Decodable {
    let id: Int
    let todo: String
    let completed: Bool
}

struct TodosResponse: Decodable {
    let todos: [Todo]
}

class APIClient {
    func fetchTodos(completion: @escaping (Result<[Todo], Error>) -> Void) {
        guard let url = URL(string: "https://dummyjson.com/todos") else {
            completion(.failure(URLError(.badURL)))
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let e = error {
                completion(.failure(e))
                return
            }
            guard let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }
            do {
                let decoded = try JSONDecoder().decode(TodosResponse.self, from: data)
                completion(.success(decoded.todos))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}


