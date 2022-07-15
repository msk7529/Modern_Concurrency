//
//  ThreadLogger.swift
//  TaskTest
//
//  Created on 2022/07/15.
//

import Combine
import Foundation

struct ThreadLogger {
    // Non MainActor
    
    let logPublisher: PassthroughSubject<String, Never>
    
    init(logPublisher: PassthroughSubject<String, Never>) {
        self.logPublisher = logPublisher
    }
    
    func printThreadInfo(function: StaticString, additionalText: String = "") {
        let log = "\(function) \(additionalText) -> \(Thread.current)"
        logPublisher.send(log)
    }
}
