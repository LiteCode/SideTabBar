//
//  TabBarButton.swift
//  MasterDetail
//
//  Created by Vladislav Prusakov on 02.09.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

import UIKit

class TabBarButton: UIControl {

    private let stackView = UIStackView()
    private let imageView = UIImageView()
    private let imageContainerView = UIView()

    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    var axis: NSLayoutConstraint.Axis {
        get { return self.stackView.axis }
        set { self.stackView.axis = newValue }
    }

    override var isSelected: Bool {
        didSet {
            self.updateTintColor()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateTintColor()
    }

    weak var tabBarItem: UITabBarItem?
    private var itemTintColor: UIColor
    private var itemUnselectedTintColor: UIColor

    init(item: UITabBarItem, tabBar: SideTabBar, target: Any, action: Selector) {
        itemTintColor = tabBar.tintColor
        itemUnselectedTintColor = tabBar.unselectedItemTintColor ?? UIColor(white: 0.57, alpha: 1)

        super.init(frame: .zero)
        self.setup()
        self.addTarget(target, action: action, for: .touchUpInside)

        let image = item.image ?? item.selectedImage
        
        self.imageView.image = image?.withRenderingMode(.alwaysTemplate).withAlignmentRectInsets(item.imageInsets)

        self.tabBarItem = item
    }

    private func setup() {

        self.updateTintColor()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        imageContainerView.addSubview(imageView)
        
        imageContainerView.isUserInteractionEnabled = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = false
        stackView.isUserInteractionEnabled = false

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
        ])

        self.addSubview(stackView)
        stackView.addArrangedSubview(imageContainerView)

        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1)
        ])
    }

    private func updateTintColor() {
        if isSelected {
            self.imageView.tintColor = itemTintColor
        } else {
            self.imageView.tintColor = itemUnselectedTintColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
