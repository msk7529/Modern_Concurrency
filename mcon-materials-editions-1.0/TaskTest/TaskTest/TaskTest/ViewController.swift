//
//  ViewController.swift
//
//  Created on 2021/07/15.
//

import UIKit

final class ViewController: UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        testTask1()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    func testTask1() {
        Task {
            // Task.init으로 생성한 Task는 caller의 context를 그대로 물려받는다. 콜러는 VC, 즉 MainAcotr이므로 메인스레드에서 await 전과 후에 모두 main 쓰레드에서 동작함.
            self.printThreadInfo(function: #function)    // main
            await self.asyncTestWithoutTaskBlock()  // main -> bg
            self.printThreadInfo(function: #function)    // main
        }
    }
    
    func testTask2() {
        Task {
            // 그러나.. 첫번째 printThreadInfo 메서드 호출을 제거하면 bgThread에서 동작하는데, 이건 이유가 뭘까.. Task 생성후 즉시 await로 쓰레드제어권을 시스템에 넘겨주면 Task.detached로 생성한 것처럼 되는건가? await후에 메인쓰레드로 돌아오는거 보면 그것도 아닌거 같은데.
            await asyncTestWithoutTaskBlock()  // bg -> bg
            printThreadInfo(function: #function)    // main
            // self.threadLogger.printThreadInfo(function: #function)  // man
        }
    }
    
    func testDetachedTask() {
        Task.detached {
            // Task.detached로 생성된 Task는 parent context에 관계없이 별도쓰레드에서 동작함.
            ThreadLogger.printThreadInfo(function: #function)  // bg
            await self.printThreadInfo(function: #function)    // main. printThreadInfo가 VC(MainActor)의 메서드여서
            await self.asyncTestWithoutTaskBlock()  // bg
            await self.printThreadInfo(function: #function)    // main
            ThreadLogger.printThreadInfo(function: #function)  // bg
        }
    }
    
    func testTaskInNotMainActor() {
        let object = NonMainActorObject()
        object.createTask()
        printThreadInfo(function: #function)    // main
    }

    func asyncTestWithoutTaskBlock() async {
        print("===============")
        printThreadInfo(function: #function, additionalText: "before sleep")    // 콜러의 쓰레드
        try? await Task.sleep(nanoseconds: 100000000)   // 쓰레드 변경
        printThreadInfo(function: #function, additionalText: "after sleep")     // 변경된 쓰레드에서
        print("===============")
    }
}

extension ViewController {
    // async method 안에서 호출하면 main에서 실행되지 않음. Task 안에서 호출해야 main 쓰레드에서 실행됨
    func printThreadInfo(function: StaticString, additionalText: String = "") {
        print("\(function) \(additionalText) -> \(Thread.current)")
    }
}
