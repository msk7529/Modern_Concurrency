//
//  ThreadLogger.swift
//  TaskTest
//
//  Created on 2022/07/15.
//

import Foundation

struct ThreadLogger {
    // Non MainActor
    
    static func printThreadInfo(function: StaticString, additionalText: String = "") {
        print("\(function) \(additionalText) -> \(Thread.current)")
    }
}
