//
//  ViewController.swift
//  FreshChiken
//
//  Created by D K on 07.04.2025.
//

import SwiftUI

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        showGame()
                
                func showGame() {
                    // Створення SwiftUI View
                    let mainView = InitialPointView()
                    // Створення UIHostingController для вашого SwiftUI View
                    let hostingController = UIHostingController(rootView: mainView)
                    
                    // Додавання UIHostingController до вашого UIKit інтерфейсу
                    addChild(hostingController)
                    view.addSubview(hostingController.view)
                    hostingController.didMove(toParent: self)
                    
                    // Налаштування розміщення і розміру SwiftUI View
                    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                    NSLayoutConstraint.activate([
                        hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
                        hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                        hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                        hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                    ])
                }    }


}

