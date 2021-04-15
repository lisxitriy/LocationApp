//
//  String+AddText.swift
//  LocationApp
//
//  Created by Olga Trofimova on 13.04.2021.
//

import Foundation

extension String {
    mutating func add(text: String?, separatedBy separator: String = "") {
        if let text = text {
            if !isEmpty {
                self += separator
            }
            self += text
        }
    }
}
