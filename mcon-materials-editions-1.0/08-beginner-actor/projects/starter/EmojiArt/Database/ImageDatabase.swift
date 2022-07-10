/// Copyright (c) 2022 Razeware LLC
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
import UIKit

@globalActor actor ImageDatabase {
    static let shared = ImageDatabase()     // GlobalActor 프로토콜을 만족하기 위해 shared 프로퍼티 추가
    
    let imageLoader = ImageLoader()         // ImageLoader 인스턴스를 사용하여 서버에서 아직 가져오지 않은 이미지를 자동으로 가져온다.

    private var storage: DiskStorage!       // 디스크 액세스 계층을 처리하는 클래스
    private var storedImagesIndex = Set<String>()   // 디스크에 있는 영구 파일의 인덱스. 이렇게 하면 ImageDatabase에 요청을 보낼 때마다 파일시스템을 확인하지 않아도 된다.
    
    func setUp() async throws {
        // DiskStorage를 초기화하고, 디스크에 있는 모든 파일들을 읽어와 인덱스를 저장해둔다.
        storage = await DiskStorage()
        for fileURL in try await storage.persistedFiles() {
            storedImagesIndex.insert(fileURL.lastPathComponent)
        }
        await imageLoader.setUp()
    }
    
    func store(image: UIImage, forKey key: String) async throws {
        // image를 PNG형식으로 내보내어 디스크에 저장
        guard let data = image.pngData() else {
            throw "Could not save image \(key)"
        }
        
        let fileName = DiskStorage.fileName(for: key)
        try await storage.write(data, name: fileName)
        storedImagesIndex.insert(fileName)
    }

    func image(_ key: String) async throws -> UIImage {
        let keys = await imageLoader.cache.keys
        if keys.contains(key) {
            // 키를 imageLoader.cache.keys에서 바로 체크하지 않고 한 번 패치한 후에 체크하는 이유는, keys가 업데이트 되는 타이밍이랑 맞물릴 경우에 메모리 충돌이 발생할 수 있기 때문이다.
            // 메모리에 이미지가 존재하는 경우엔 메모리에서 가져온다.
            print("Cached in-memory")
            return try await imageLoader.image(key)
        }
        
        do {
            // 디스크에 있는지 확인한다.
            let fileName = DiskStorage.fileName(for: key)
            if !storedImagesIndex.contains(fileName) {
                throw "Image not persisted"
            }
            
            // 디스크에 있으면, 읽어와서 UIImage로 변화한다.
            let data = try await storage.read(name: fileName)
            guard let image = UIImage(data: data) else {
                throw "Invalid image data"
            }
            
            print("Cached on disk")
            
            // 인메모리 캐시에 저장한다.
            await imageLoader.add(image, forKey: key)
            return image
        } catch {
            // 서버에서 이미지를 받아온다. 모든 로컬 시도가 실패하여 네트워크 호출을 해야하는 경우 실행됨.
            let image = try await imageLoader.image(key)
            try await store(image: image, forKey: key)
            return image
        }
    }
    
    func clear() async {
        for name in storedImagesIndex {
            try? await storage.remove(name: name)
        }
        storedImagesIndex.removeAll()
    }
}
