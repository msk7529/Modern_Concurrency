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

/// A single scanning task.
struct ScanTask: Identifiable {
    let id: UUID
    let input: Int
    
    init(input: Int, id: UUID = UUID()) {
        self.id = id
        self.input = input
    }
    
    /// A method that performs the scanning.
    /// > Note: This is a mock method that just suspends for a second.
    func run() async throws -> String {
        try await UnreliableAPI.shared.action(failingEvery: 10)     // 10번째마다 에러를 발생시킨다.
        
        await Task(priority: .medium) {
            // Task에 medium의 우선순위를 주어 UI 업데이트가 바로바로 이루어지도록 한다. 즉, 스케쥴러는 다음 스캔을 시작하는 것보다 완료된 스캔 후 재개를 선호해야 한다.(그래야 자연스러워 보이니까)
            // 우선순위를 높게 한다고 해서, 작업 자체가 더 빨라지는건 아님. 단지 실행큐의 앞으로 데려오는 것 뿐.
            // Block the thread as a real heavy-computation functon will.
            Thread.sleep(forTimeInterval: 1)
        }.value
        
        return "\(input)"
    }
}
