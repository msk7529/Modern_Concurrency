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
        // run이 완료되면, 동시성시스템은 이제 다른 스케쥴된 task를 실행할지, 아니면 완료된 작업을 재개할지 결정한다. 이 때 우선순위를 따로 주지 않으면, 먼저 요청한 순서대로 작업이 이루어진다.
        // priority를 지정하지 않으면 Task는 부모의 우선순위를 갖게되며, 이 경우는 메인 스레드에서 origin Task가 수행되었으므로 .userInitiated가 된다.
        
        await onTaskCompleted()
        return result
    }
    
    func runAllTasks() async throws {
        started = Date()
        
        /*
        var scans: [String] = []
        for number in 0..<total {
            // Dispatcher가 몇 개의 스레드를 사용하던지에 관계없이, 이 코드가 다음 실행을 block 하게 된다. 즉 직렬로 수행하게 됨.
            scans.append(await worker(number: number))
        }
        print(scans)
        */
        
        let scans = await withTaskGroup(of: String.self, body: { [unowned self] group -> [String] in
            for number in 0..<total {
                // addTask는 그 즉시 리턴된다. 즉, 20개의 작업들은 작업들이 시작하기 전에 이미 스케쥴된다.
                group.addTask {
                    await self.worker(number: number)   // 병렬로 수행되므로, data race condition이 발생하지 않는지 반드시 확인해야한다. 대부분의 경우 컴파일러는 race condition 여부를 체크하지 못한다.
                }
            }
            
            return await group
                .reduce(into: [String]()) { result, string in
                    result.append(string)
                }
        })
        
        // TaskGroup은 시스템 리소스에 최적화하는데 적합하다고 판단되는 Task의 순서대로 실행하기 때문에 scans는 오름차순을 보장하지 못한다.
        print("runAllTasks() finished... \(scans)")
    }
    
    func runAllTaskWithProcessingTaskResultsInRealTime() async throws {
        // runAllTask와 유사하나, 실시간으로 작업 결과를 처리할 수 있다.
        
        await withTaskGroup(of: String.self, body: { [unowned self] group in
            for number in 0..<total {
                group.addTask {
                    await self.worker(number: number)
                }
            }
            
            for await result in group {
                print("Completed: \(result)")
            }
            print("runAllTaskWithProcessingTaskResultsInRealTime() finished...")
        })
    }
    
    func runAllTaskWithBatchSize() async throws {
        // runAllTaskWithProcessingTaskResultsInRealTime와 유사하나, 동시에 4개 이하의 작업을 실행하도록 제한하여 앱이 시스템에 과부하를 주지 않도록 한다.
        await withTaskGroup(of: String.self, body: { [unowned self] group in
            let batchSize = 4
            
            for index in 0..<batchSize {
                group.addTask {
                    await self.worker(number: index)
                }
            }
            
            var index = batchSize
            
            for await result in group {
                print("Completed: \(result)")
                
                if index < total {
                    group.addTask { [index] in  // index 캡처
                        await self.worker(number: index)
                    }
                    index += 1
                }
            }
            print("runAllTaskWithBatchSize() finished...")
        })
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
