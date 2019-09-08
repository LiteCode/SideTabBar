//
//  TestViewController.swift
//  SideTabBar_Example
//
//  Created by Vladislav Prusakov on 08.09.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class TestViewController: UIViewController {
    
    private weak var label: UILabel!
    
    init(tabBarItem: UITabBarItem) {
        super.init(nibName: nil, bundle: nil)
        self.tabBarItem = tabBarItem
    }
    
    init(name: String) {
        super.init(nibName: nil, bundle: nil)
        self.tabBarItem = UITabBarItem(title: name, image: nil, selectedImage: nil)
    }
    
    deinit {
        print("deinited controller with title:", tabBarItem.title ?? "<WITHOUT TITLE>")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.leftBarButtonItem = self.sideTabBarController?.displayModeButtonItem
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Primary Overlay", style: .done, target: self, action: #selector(onChangePreferredStyle(_:)))
        
        let label = UILabel()
        label.text = self.tabBarItem.title ?? self.tabBarItem.description
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        self.view.addSubview(label)
        self.label = label
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            label.leftAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leftAnchor)
        ])
    }
    
    @objc func onChangePreferredStyle(_ button: UIBarButtonItem) {
        let isAllVisible = self.sideTabBarController?.prefferedDisplayMode == .allVisible
        button.title = isAllVisible ? "Primary Overlay" : "All Visible"
        self.sideTabBarController?.prefferedDisplayMode = isAllVisible ? .primaryOverlay : .allVisible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
