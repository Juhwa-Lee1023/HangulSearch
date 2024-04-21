//
//  JSONLoader.swift
//
//
//  Created by 이주화 on 4/21/24.
//

import Foundation

class JSONLoader {
    func loadJSON(from filename: String) -> String? {
        if let path = Bundle.module.url(forResource: filename, withExtension: "json") {
            do {
                let data = try String(contentsOfFile: path.path, encoding: .utf8)
                return data
            } catch {
                print("Error reading JSON file:", error.localizedDescription)
                return nil
            }
        } else {
            print("JSON file not found.")
            return nil
        }
    }
}
