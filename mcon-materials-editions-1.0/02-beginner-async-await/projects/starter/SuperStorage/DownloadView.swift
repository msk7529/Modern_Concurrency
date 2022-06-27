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

import SwiftUI
import UIKit

/// The file download view.
struct DownloadView: View {
    /// The selected file.
    let file: DownloadFile
    @EnvironmentObject var model: SuperStorageModel
    /// The downloaded data.
    @State var fileData: Data?
    /// Should display a download activity indicator.
    @State var isDownloadActive = false
    @State var downloadTask: Task<Void, Error>?
    var body: some View {
        List {
            // Show the details of the selected file and download buttons.
            FileDetails(
                file: file,
                isDownloading: !model.downloads.isEmpty,
                isDownloadActive: $isDownloadActive,
                downloadSingleAction: {
                    // silver 버튼: Download a file in a single go. 다운로드가 완전히 완료되면, 프로그레스바가 업데이트 된다.
                    // fileData = try await model.download(file: file): 에러 -> downloadSingleAction가 async 클로저를 받을 수 없음. 따라서 아래처럼 수행
                    isDownloadActive = true
                    Task {
                        // 동기 컨텍스트에서 비동기 컨텍스트를 생성하여 수행한다.
                        do {
                            fileData = try await model.download(file: file)
                        } catch { }
                        isDownloadActive = false
                    }
                },
                downloadWithUpdatesAction: {
                    // gold 버튼: Download a file with UI progress updates. 다운로드 진행률이 실시간으로 프로그레스바에 업데이트 된다.
                    isDownloadActive = true
                    downloadTask = Task {
                        do {
                            fileData = try await model.downloadWithProgress(file: file)
                        } catch {
                            if let error = error as? CancellationError {
                                print(error.localizedDescription)
                            }
                        }
                        isDownloadActive = false
                    }
                },
                downloadMultipleAction: {
                    // Download a file in multiple concurrent parts.
                }
            )
            if !model.downloads.isEmpty {
                // Show progress for any ongoing downloads.
                Downloads(downloads: model.downloads)
            }
            if let fileData = fileData {
                // Show a preview of the file if it's a valid image.
                FilePreview(fileData: fileData)
            }
        }
        .animation(.easeOut(duration: 0.33), value: model.downloads)
        .listStyle(InsetGroupedListStyle())
        .toolbar(content: {
            Button(action: {
            }, label: { Text("Cancel All") })
                .disabled(model.downloads.isEmpty)
        })
        .onDisappear {
            fileData = nil
            model.reset()
            downloadTask?.cancel()  // downloadTask를 취소시키고 뿐만 아니라 child tasks 까지 취소시킨다.
        }
    }
}
