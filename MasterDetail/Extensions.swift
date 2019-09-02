//
//  Extensions.swift
//  MasterDetail
//
//  Created by Vladislav Prusakov on 02.09.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

import UIKit

extension UIView {
    static func perform(usingAnimation: Bool, block: () -> Void) {
        if usingAnimation {
            block()
        } else {
            UIView.performWithoutAnimation {
                block()
            }
        }
    }
}

extension NSLayoutConstraint {
        @IBInspectable var pxConstant: CGFloat {
        get { return self.constant * UIScreen.main.scale }
        set { self.constant = newValue / UIScreen.main.scale }
    }
}

extension UIBlurEffect {
    
    enum ThroughStyle: Int64 {
        case fullThrough = 2
        case throughWhileActive = 1
    }
    
    static func makeBlurThroughEffect(style: ThroughStyle) -> UIVisualEffect {
        return _UIBlurThroughEffect._blurThrough(withStyle: style.rawValue)
    }
}

extension UIColor {
    static let barHairlineColor = UIColor(white: 0, alpha: 0.3)
}

extension Collection {
    subscript(safe index: Index) -> Element? {
        return self.indices.contains(index) ? self[index] : nil
    }
}

extension UIViewController {
    
    func removeFromParentViewController() {
        self.willMove(toParent: nil)
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    /// Adds a child view controller pinning it view to edges of viewContainer
    func addChildViewController(_ viewController: UIViewController, viewContainer: UIView) {
        self.addChildViewController(viewController) { (view) in
            viewContainer.insertSubview(view, at: 0)
            view.frame.size = viewContainer.frame.size
            view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        }
    }
    
    /// Adds a child view controller calling viewConfigurator to embed view
    func addChildViewController(_ viewController: UIViewController, viewConfigurator: (UIView) -> Void) {
        self.addChild(viewController)
        viewConfigurator(viewController.view)
        viewController.didMove(toParent: self)
    }
}

public extension UIViewController {
    var sideTabBarController: TabBarViewController? {
        if let tabBar = self.parent as? TabBarViewController {
            return tabBar
        } else if let navController = self.parent as? UINavigationController {
            return navController.sideTabBarController
        } else if let tabController = self.parent as? UITabBarController {
            return tabController.sideTabBarController
        }
        
        return nil
    }
}
