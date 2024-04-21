//
//  JSONParser.swift
//
//
//  Created by 이주화 on 4/21/24.
//

import Foundation

class JSONParser {
    func parseJSON(_ jsonString: String) -> [Person] {
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("Failed to convert string to data.")
            return [Person(name: "test", age: 123)]
        }
        
        do {
            let people = try JSONDecoder().decode([Person].self, from: jsonData)
            return people
        } catch {
            print("Error parsing JSON:", error.localizedDescription)
            return [Person(name: "test", age: 123)]
        }
    }
}
