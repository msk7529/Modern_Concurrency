//
//  NonMainActorObject.swift
//  TaskTest
//
//  Created on 2022/07/15.
//

import Foundation

final class NonMainActorObject {
        
    func createTask() {
        Task {
            ThreadLogger.printThreadInfo(function: #function)  // bg
        }
    }
}
