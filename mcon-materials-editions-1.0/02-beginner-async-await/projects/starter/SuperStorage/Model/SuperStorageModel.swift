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

/// The download model.
class SuperStorageModel: ObservableObject {
    /// The list of currently running downloads.
    @Published var downloads: [DownloadInfo] = []
    
    @TaskLocal static var supportsPartialDownloads = false  // Task-local property는 타입에 대해 static 이거나, 글로벌 변수여야 한다. @TaskLocal property wraaper는 비동기 작업에 값을 바인딩 하거나, task hierarchy에 값을 삽입하는 withValue() 메서드를 제공한다.
    
    func availableFiles() async throws -> [DownloadFile] {
        print("availableFiles start.")
        
        guard let url = URL(string: "http://localhost:8080/files/list") else {
            throw "Colud not create the URL."
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw "The server responded with an error."
        }
        
        guard let list = try? JSONDecoder().decode([DownloadFile].self, from: data) else {
            throw "The server response was not recognized."
        }
        
        print("availableFiles finished.")
        return list
    }
    
    func stats() async throws -> String {
        print("stats start.")
        
        guard let url = URL(string: "http://localhost:8080/files/status") else {
            throw "Could not create the URL."
        }
                
        let (data, response) = try await URLSession.shared.data(from: url)
                
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw "The server responded with an error."
        }
        
        print("stats finished.")
        return String(decoding: data, as: UTF8.self)
    }
    
    /// Downloads a file and returns its content.
    func download(file: DownloadFile) async throws -> Data {
        guard let url = URL(string: "http://localhost:8080/files/download?\(file.name)") else {
            throw "Could not create the URL."
        }
        
        await addDownload(name: file.name)
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        await updateDownload(name: file.name, progress: 1.0)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw "The server responded with an error."
        }
        
        return data
    }
    
    /// Downloads a file, returns its data, and updates the download progress in ``downloads``.
    func downloadWithProgress(file: DownloadFile) async throws -> Data {
        return try await downloadWithProgress(fileName: file.name, name: file.name, size: file.size)
    }
    
    /// Downloads a file, returns its data, and updates the download progress in ``downloads``.
    private func downloadWithProgress(fileName: String, name: String, size: Int, offset: Int? = nil) async throws -> Data {
        guard let url = URL(string: "http://localhost:8080/files/download?\(fileName)") else {
            throw "Could not create the URL."
        }
        await addDownload(name: name)
        
        let result: (downloadStream: URLSession.AsyncBytes, response: URLResponse)
        
        if let offset = offset {
            // 전체 응답을 한 번에 얻어오는 대신에, 응답의 바이트 범위를 받아오도록 요청한다.
            // 이러한 partial request을 사용하면, 파일을 여러 부분으로 나우어 병렬적으로 다운로드 받을 수 있다.
            let urlRequest = URLRequest(url: url, offset: offset, length: size)
            result = try await URLSession.shared.bytes(for: urlRequest, delegate: nil)
            
            guard (result.response as? HTTPURLResponse)?.statusCode == 206 else {
                throw "The server responded with an error."
            }
        } else {
            // partial request가 아닌 일반적인 요청을 처리하는 블럭
            result = try await URLSession.shared.bytes(from: url, delegate: nil)
            
            guard (result.response as? HTTPURLResponse)?.statusCode == 200 else {
                throw "The server responded with an error."
            }
        }
        
        // partial 또는 standard request에 관계없이 result.downloadStream 으로 사용할 수 있는 비동기 바이트 시퀀스를 얻는다.
        
        var asyncDownloadIterator = result.downloadStream.makeAsyncIterator()
        var accumulator = ByteAccumulator(name: name, size: size)
        
        while !stopDownloads, !accumulator.checkCompleted() {
            // checkCompleted: accumulator가 bytes를 더 받을 수 있으면 false
            // 이 두 조건의 조합은 외부 플래그가 해제되거나, 누산기가 다운로드를 완료할 때까지 루프를 실행할 수 있는 유연성을 제공한다.
            while !accumulator.isBatchCompleted, let byte = try await asyncDownloadIterator.next() {
                accumulator.append(byte)
            }
            
            let progress = accumulator.progress
            
            Task.detached(priority: .medium) {
                // Task.detached는 동시성 모델의 효율성에 부정적인 영향을 미치므로 사용하는 것을 지양하지만, 여기서는 사용하도록 한다.
                // detached task는 부모의 우선순위, task storage, execution actor을 상속하지 않는다.
                await self.updateDownload(name: name, progress: progress)
            }
            print(accumulator.description)
        }
        
        if stopDownloads, !Self.supportsPartialDownloads {
            throw CancellationError()
        }
        
        return accumulator.data
    }
    
    /// Downloads a file using multiple concurrent connections, returns the final content, and updates the download progress.
    func multiDownloadWithProgress(file: DownloadFile) async throws -> Data {
        func partInfo(index: Int, of count: Int) -> (offset: Int, size: Int, name: String) {
            let standardPartSize = Int((Double(file.size) / Double(count)).rounded(.up))
            let partOffset = index * standardPartSize
            let partSize = min(standardPartSize, file.size - partOffset)
            let partName = "\(file.name) (part \(index + 1))"
            return (offset: partOffset, size: partSize, name: partName)
        }
        let total = 4
        let parts = (0..<total).map { partInfo(index: $0, of: total) }
        // Add challenge code here.
        return Data()
    }
    
    /// Flag that stops ongoing downloads.
    var stopDownloads = false
    
    func reset() {
        stopDownloads = false
        downloads.removeAll()
    }
}

extension SuperStorageModel {
    /// Adds a new download.
    @MainActor func addDownload(name: String) {
        let downloadInfo = DownloadInfo(id: UUID(), name: name, progress: 0.0)
        downloads.append(downloadInfo)
    }
    
    /// Updates a the progress of a given download.
    @MainActor func updateDownload(name: String, progress: Double) {
        if let index = downloads.firstIndex(where: { $0.name == name }) {
            var info = downloads[index]
            info.progress = progress
            downloads[index] = info
        }
    }
}
