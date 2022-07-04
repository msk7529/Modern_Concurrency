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

class ScanModel: ObservableObject {
    // MARK: - Private state
    private var counted = 0
    private var started = Date()
    
    // MARK: - Public, bindable state
    
    /// Currently scheduled for execution tasks.
    @MainActor @Published var scheduled = 0
    
    /// Completed scan tasks per second.
    @MainActor @Published var countPerSecond: Double = 0
    
    /// Completed scan tasks.
    @MainActor @Published var completed = 0
    
    @Published var total: Int
    
    @MainActor @Published var isCollaborating = false
    
    // MARK: - Methods
    
    init(total: Int, localName: String) {
        self.total = total
    }
    
    func worker(number: Int) async -> String {
        await onScheduled()
        
        let task = ScanTask(input: number)
        let result = await task.run()
        
        await onTaskCompleted()
        return result
    }
    
    func runAllTasks() async throws {
        started = Date()
        
        var scans: [String] = []
        for number in 0..<total {
            // Dispatcher가 몇 개의 스레드를 사용하던지에 관계없이, 이 코드가 다음 실행을 block 하게 된다. 즉 직렬로 수행하게 됨.
            scans.append(await worker(number: number))
        }
        print(scans)
    }
}

// MARK: - Tracking task progress.
extension ScanModel {
    @MainActor
    private func onTaskCompleted() {
        // update model counters. UI updates.
        completed += 1
        counted += 1
        scheduled -= 1
        
        countPerSecond = Double(counted) / Date().timeIntervalSince(started)
    }
    
    @MainActor
    private func onScheduled() {
        // update model counters. UI updates.
        scheduled += 1
    }
}
