//
//  ButtonCreater.swift
//  TaskTest
//
//  Created on 2022/07/15.
//

import UIKit

final class ButtonCreater: NSCoder {
    
    func create(title: String) -> UIButton {
        let button: UIButton = .init(frame: .zero)
        button.backgroundColor = .blue.withAlphaComponent(0.3)
        button.setTitleColor(.black, for: .normal)
        button.setTitle(title, for: .normal)
        button.titleLabel?.textAlignment = .center
        var configuration: UIButton.Configuration = .plain()
        configuration.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
