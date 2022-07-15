//
//  ViewController.swift
//
//  Created on 2021/07/15.
//

import Combine
import UIKit

final class ViewController: UIViewController {
    
    private lazy var buttonForTestTask1: UIButton = {
        let button = buttonCreater.create(title: "testTask1")
        button.addTarget(self, action: #selector(testTask1), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonForTestTask2: UIButton = {
        let button = buttonCreater.create(title: "testTask2")
        button.addTarget(self, action: #selector(testTask2), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonForTestDetachedTask: UIButton = {
        let button = buttonCreater.create(title: "testDetachedTask")
        button.addTarget(self, action: #selector(testDetachedTask), for: .touchUpInside)
        return button
    }()
    
    private lazy var logLabel: UILabel = {
        let label: UILabel = .init(frame: .zero)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    let buttonCreater: ButtonCreater = .init()
    
    var threadLogger: ThreadLogger!
    
    let logPublisher: PassthroughSubject<String, Never> = .init()
    
    var cancellables: Set<AnyCancellable> = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        threadLogger = .init(logPublisher: logPublisher)
        initView()
        
        logPublisher
            .collect(.byTime(DispatchQueue.main, .seconds(1)))    // 1초 단위로 그룹화해서
            .map { logs -> String in
                var result: String = ""
                for log in logs {
                    result += log + "\n"
                }
                return result
            }
            .sink { [weak self] log in
                self?.logLabel.text = log
            }.store(in: &cancellables)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        [buttonForTestTask1, buttonForTestTask2, buttonForTestDetachedTask].forEach {
            $0.layer.cornerRadius = $0.frame.height / 2
        }
    }
    
    private func initView() {
        [buttonForTestTask1, buttonForTestTask2, buttonForTestDetachedTask, logLabel].forEach {
            view.addSubview($0)
        }
        
        buttonForTestTask1.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        buttonForTestTask1.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        
        buttonForTestTask2.topAnchor.constraint(equalTo: buttonForTestTask1.topAnchor).isActive = true
        buttonForTestTask2.leadingAnchor.constraint(equalTo: buttonForTestTask1.trailingAnchor, constant: 10).isActive = true
        
        buttonForTestDetachedTask.topAnchor.constraint(equalTo: buttonForTestTask1.bottomAnchor, constant: 10).isActive = true
        buttonForTestDetachedTask.leadingAnchor.constraint(equalTo: buttonForTestTask1.leadingAnchor).isActive = true
        
        logLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30).isActive = true
        logLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10).isActive = true
        logLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10).isActive = true
    }
    
    @objc func testTask1() {
        Task {
            // Task.init으로 생성한 Task는 caller의 context를 그대로 물려받는다. 콜러는 VC, 즉 MainAcotr이므로 메인스레드에서 await 전과 후에 모두 main 쓰레드에서 동작함.
            self.printThreadInfo(function: #function)    // main
            await self.asyncTestWithoutTaskBlock()  // main -> bg
            self.printThreadInfo(function: #function)    // main
        }
    }
    
    @objc func testTask2() {
        Task {
            // 그러나.. 첫번째 printThreadInfo 메서드 호출을 제거하면 bgThread에서 동작하는데, 이건 이유가 뭘까.. Task 생성후 즉시 await로 쓰레드제어권을 시스템에 넘겨주면 Task.detached로 생성한 것처럼 되는건가? await후에 메인쓰레드로 돌아오는거 보면 그것도 아닌거 같은데.
            await asyncTestWithoutTaskBlock()  // bg -> bg
            printThreadInfo(function: #function)    // main
            // self.threadLogger.printThreadInfo(function: #function)  // man
        }
    }
    
    @objc func testDetachedTask() {
        Task.detached {
            // Task.detached로 생성된 Task는 parent context에 관계없이 별도쓰레드에서 동작함.
            await self.threadLogger.printThreadInfo(function: #function)  // bg
            await self.printThreadInfo(function: #function)    // main. printThreadInfo가 VC(MainActor)의 메서드여서
            await self.asyncTestWithoutTaskBlock()  // bg
            await self.printThreadInfo(function: #function)    // main
            await self.threadLogger.printThreadInfo(function: #function)  // bg
        }
    }
    
    func testTaskInNotMainActor() {
        let object = NonMainActorObject(logPublihser: logPublisher)
        object.createTask()
        printThreadInfo(function: #function)    // main
    }

    func asyncTestWithoutTaskBlock() async {
        logPublisher.send("===============")
        printThreadInfo(function: #function, additionalText: "before sleep")    // 콜러의 쓰레드
        try? await Task.sleep(nanoseconds: 10000000)   // 쓰레드 변경
        printThreadInfo(function: #function, additionalText: "after sleep")     // 변경된 쓰레드에서
        logPublisher.send("===============")
    }
}

extension ViewController {
    // async method 안에서 호출하면 main에서 실행되지 않음. Task 안에서 호출해야 main 쓰레드에서 실행됨
    func printThreadInfo(function: StaticString, additionalText: String = "") {
        let log = "\(function) \(additionalText) -> \(Thread.current)"
        logPublisher.send(log)
    }
}
