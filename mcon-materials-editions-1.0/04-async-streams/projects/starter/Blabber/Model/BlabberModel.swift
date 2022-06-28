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

import Foundation
import CoreLocation
import Combine
import UIKit

/// The app model that communicates with the server.
class BlabberModel: ObservableObject {
    var username = ""
    var urlSession = URLSession.shared
    
    init() {
    }
    
    /// Current live updates
    @Published var messages: [Message] = []
    
    /// Shares the current user's address in chat.
    func shareLocation() async throws {
    }
    
    func observeAppStatus() async {
        for await _ in await NotificationCenter.default.notifications(for: UIApplication.willResignActiveNotification) {
            // 다른 앱으로 전환하거나, 백그라운드로 내려가서 현재 앱이 더 이상 활성화되지 않으면 notification post
            try? await say("\(username) went away", isSystemMessage: true)
        }
    }
    
    /// Does a countdown and sends the message.
    func countdown(to message: String) async throws {
        guard !message.isEmpty else { return }
        
        // 매초마다 String value를 만드는 AsyncStream을 정의. 이러면 AsyncSequence, AsyncIteratorProtocol 구현없이 쉽게 비동기시퀀스를 만들어낼 수 있다.
        let counter = AsyncStream<String>.init { continuation in
            var countdown = 3
            
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                guard countdown > 0 else {
                    timer.invalidate()
                    /* finish() 말고 yield를 통해서도 시퀀스를 완료할 수 있다.
                    continuation.yield(">>> \(message)")
                    continuation.finish()
                    */
                    continuation.yield(with: .success(">>> \(message)"))
                    return
                }
                
                continuation.yield("\(countdown)...")
                countdown -= 1
            }
        }
        
        for await countdownMessage in counter {
            try await say(countdownMessage)
        }
    }
    
    /// Start live chat updates
    @MainActor
    func chat() async throws {
        guard
            let query = username.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: "http://localhost:8080/chat/room?\(query)")
        else {
            throw "Invalid username"
        }
        
        let (stream, response) = try await liveURLSession.bytes(from: url, delegate: nil)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw "The server responded with an error."
        }
        
        print("Start live updates")
        
        try await withTaskCancellationHandler {
            // task가 취소되면 동작하는 핸들러
            print("End live updates")
            messages = []
        } operation: {
            try await readMessages(stream: stream)
        }
    }
    
    /// Reads the server chat stream and updates the data model.
    @MainActor
    private func readMessages(stream: URLSession.AsyncBytes) async throws {
        var iterator = stream.lines.makeAsyncIterator()
        
        // 서버가 잘 동작하는지 확인하기 위해, 첫번째 응답만 받아온다.
        guard let first = try await iterator.next() else {
            throw "No response from server."
        }
        
        guard let data = first.data(using: .utf8), let status = try? JSONDecoder().decode(ServerStatus.self, from: data) else {
            throw "Invalid response from server"
        }
        
        messages.append(Message(message: "\(status.activeUsers) active users"))
        
        let notifications = Task {
            await observeAppStatus()
        }
        
        defer {
            notifications.cancel()
        }
        
        for try await line in stream.lines {
            if let data = line.data(using: .utf8), let update = try? JSONDecoder().decode(Message.self, from: data) {
                messages.append(update)
            }
        }
    }
    
    /// Sends the user's message to the chat server
    func say(_ text: String, isSystemMessage: Bool = false) async throws {
        guard
            !text.isEmpty,
            let url = URL(string: "http://localhost:8080/chat/say")
        else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = try JSONEncoder().encode(
            Message(id: UUID(), user: isSystemMessage ? nil : username, message: text, date: Date())
        )
        
        let (_, response) = try await urlSession.data(for: request, delegate: nil)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw "The server responded with an error."
        }
    }
    
    /// A URL session that goes on indefinitely, receiving live updates.
    private var liveURLSession: URLSession = {
        var configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = .infinity
        return URLSession(configuration: configuration)
    }()
}
