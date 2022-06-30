//
//  TimeoutTask.swift
//  BlabberTests
//
//  Created by kakao on 2022/07/01.
//

import Foundation

class TimeoutTask<Success> {
    
    var value: Success {
        get async throws {
            try await withCheckedThrowingContinuation({ continuation in
                self.continuation = continuation
                
                // 두 개의 비동기 작업이 병렬로 시작하고, 먼저 완료작업이 continuation resume하고 느린 작업은 취소된다.
                // 아주 드물게 두 작업이 정확히 continuation을 사용하려고 하여 충돌이 발생할 수 있다.
                // 이후 actor을 이용하여 안전한 동시성 코드를 작성할 예정이니 여기에서는 그대로 둔다.
                Task {
                    try await Task.sleep(nanoseconds: nanoseconds)
                    self.continuation?.resume(throwing: TimeoutError())
                    self.continuation = nil
                }
                
                Task {
                    let result = try await operation()
                    self.continuation?.resume(returning: result)
                    self.continuation = nil
                }
            })
        }
    }
    
    let nanoseconds: UInt64     // 최대 지속시간
    let operation: @Sendable () async throws -> Success
    
    private var continuation: CheckedContinuation<Success, Error>?
    
    init(seconds: TimeInterval, operation: @escaping @Sendable () async throws -> Success) {
        // @escaping: 이니셜라이저 외부에서 클로저를 저장하고 실행할 수 있음
        // @Sendable: 클로저 또는 함수 유형이 Sendable 프로토콜을 준수함을 나타낸다. 즉, 동시성 도메인 간에 전송하는 것이 안전하다.
        // async: 클로저가 concurrent asynchronous context에서 실행되어야 함을 나타낸다.
        // throws: 클로저에서 오류가 발생할 수 있음을 나타낸다.
        self.nanoseconds = UInt64(seconds * 1_000_000_000)
        self.operation = operation
    }
    
    func cancle() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

extension TimeoutTask {
    struct TimeoutError: LocalizedError {
        var errorDescription: String? {
            return "The operation timed out."
        }
    }
}
