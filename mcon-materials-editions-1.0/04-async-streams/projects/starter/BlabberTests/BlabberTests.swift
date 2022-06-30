/// Copyright (c) 2021 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import XCTest
@testable import Blabber

class BlabberTests: XCTestCase {
    
    let model: BlabberModel = {
        let model: BlabberModel = .init()
        model.username = "test"
        
        let testConfiguration = URLSessionConfiguration.default
        testConfiguration.protocolClasses = [TestURLProtocol.self]
        
        model.urlSession = URLSession(configuration: testConfiguration)
        return model
    }()
    
    func testMoelSay() async throws {
        try await model.say("Hello!")
        
        let request = try XCTUnwrap(TestURLProtocol.lastRequest)
        // 올바른 URL로 요청을 보냈는지 검증
        XCTAssertEqual(request.url?.absoluteString, "http://localhost:8080/chat/say")
        
        let httpBody = try XCTUnwrap(request.httpBody)
        let message = try XCTUnwrap(try? JSONDecoder().decode(Message.self, from: httpBody))
        // 메시지를 올바르게 보냈는지 검증
        XCTAssertEqual(message.message, "Hello!")
    }
    
    func testModelCountdown() async throws {
        try await model.countdownV2(to: "Tada!")    // countdown 메서드는 왜 테스트가 끝나질 않지.. Timer를 UnitTest에서는 쓸 때 오류가 있나?
        
        try await TimeoutTask(seconds: 10, operation: {
            for await request in TestURLProtocol.requests {
                print(request)
            }
        }).value
        
        // 테스트가 실패하는 이유는, 작업이 순서대로 수행되고 저장된 요청 스트림을 읽기 시작하기 전에 카운트다운이 완료되기 때문.
        // countdownV2가 수행되면 TestURLProtocol의 lastRequest가 총 4번 세팅되는데, 그 때는 continuation이 세팅되기 전이기 때문에 yield가 수행되지 않음
        // countdownV2가 완료되고 나서야 for문이 수행되는데, 여기서 TestURLProtocol.requests에 접근해봤자 아무일도 일어나지 않음.
    }
    
    func testModelCountdown2() async throws {
        async let countdown: Void = model.countdownV2(to: "Tada!")
        async let messages = TimeoutTask(seconds: 10) {
            await TestURLProtocol.requests
                .prefix(4)  // 3개의 요청만 받을 경우 테스트가 끝나지 않을 것이기 떄문에 Message를 TimeoutTask에 래핑한다.
                .compactMap { $0.httpBody }
                .compactMap { data in
                    try? JSONDecoder().decode(Message.self, from: data).message
                }.reduce(into: []) { result, request in
                    result.append(request)
                }
        }.value
        
        // 두 개의 바인딩이 준비되면, 두 개를 동시에 받아온다.
        let (messageResult, _) = try await (messages, countdown)
        
        XCTAssertEqual(["3...", "2...", "1...", "🎉 Tada!"], messageResult)
    }
}
