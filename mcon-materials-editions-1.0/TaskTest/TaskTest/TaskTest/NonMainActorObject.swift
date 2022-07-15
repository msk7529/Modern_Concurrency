//
//  NonMainActorObject.swift
//  TaskTest
//
//  Created on 2022/07/15.
//

import Combine
import Foundation

final class NonMainActorObject {
    
    let logPublisher: PassthroughSubject<String, Never>
    let threadLogger: ThreadLogger
    
    init(logPublihser: PassthroughSubject<String, Never>) {
        self.logPublisher = logPublihser
        self.threadLogger = .init(logPublisher: logPublisher)
    }
    
    func createTask() {
        Task {
            threadLogger.printThreadInfo(function: #function)  // bg
        }
    }
}
