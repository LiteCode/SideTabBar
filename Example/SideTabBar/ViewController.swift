//
//  CustomSideTabBarController.swift
//  SideTabBar_Example
//
//  Created by spectraldragon on 09/08/2019.
//  Copyright (c) 2019 spectraldragon. All rights reserved.
//

import UIKit
import SideTabBar

class CustomSideTabBarController: SideTabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // This part adding blur effect for mac version
        #if targetEnvironment(macCatalyst)
        if let effect = UIBlurEffect.makeBlurThroughEffect(style: .throughWhileActive) {
            self.backgroundVisualEffect = effect
        }
        #endif
        
        let firstController = TableTestViewController(tabBarItem: UITabBarItem(title: "Shops", image: UIImage(systemName: "cart")!, tag: 0))
        let secondController = TestViewController(tabBarItem: UITabBarItem(title: "Downloads", image: UIImage(systemName: "icloud.and.arrow.down")!, tag: 1))
        self.setViewControllers([firstController, secondController], positioning: .top, animated: false)
        
        let firstController1 = TableTestViewController(tabBarItem: UITabBarItem(title: "History", image: UIImage(systemName: "clock")!, tag: 3))
        let secondController1 = TestViewController(tabBarItem: UITabBarItem(title: "More", image: UIImage(systemName: "ellipsis")!, tag: 4))
        self.setViewControllers([firstController1, secondController1], positioning: .bottom, animated: false)
        
        let mainController = TestViewController(tabBarItem: UITabBarItem(title: "Main screen", image: nil, tag: 5))
        
        mainController.view.backgroundColor = .white
        self.setContentViewController(UINavigationController(rootViewController: mainController))
    }

}

