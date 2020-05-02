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
            self.updateView()
        }
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()
        self.updateView()
    }

    weak var tabBarItem: UITabBarItem?
    private var itemTintColor: UIColor
    private var itemUnselectedTintColor: UIColor
    private var image: UIImage?
    private var selectedImage: UIImage?

    init(item: UITabBarItem, tabBar: SideTabBar, target: Any, action: Selector) {
        itemTintColor = tabBar.tintColor
        self.selectedImage = item.selectedImage?
            .withRenderingMode(.alwaysTemplate)
            .withAlignmentRectInsets(item.imageInsets)
        
        self.itemUnselectedTintColor = tabBar.unselectedItemTintColor ?? UIColor(white: 0.57, alpha: 1)

        super.init(frame: .zero)
        self.setup()
        self.addTarget(target, action: action, for: .touchUpInside)

        self.image = item.image?.withRenderingMode(.alwaysTemplate).withAlignmentRectInsets(item.imageInsets)

        self.tabBarItem = item
    }

    private func setup() {

        self.updateView()

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
        
        #if targetEnvironment(macCatalyst)
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(onHover(_:)))
        self.addGestureRecognizer(hover)
        #else
        if #available(iOS 13.4, *) {
            let interaction = UIPointerInteraction(delegate: self)
            self.addInteraction(interaction)
        }
        #endif

        NSLayoutConstraint.activate([
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor),
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 1)
        ])
    }

    private func updateView() {
        if self.isSelected {
            self.imageView.tintColor = itemTintColor
            if let selectedImage = self.selectedImage {
                self.imageView.image = selectedImage
            }
        } else {
            self.imageView.tintColor = itemUnselectedTintColor
            self.imageView.image = self.image
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Private
    
    @objc func onHover(_ gesture: UIHoverGestureRecognizer) {
        switch gesture.state {
        case .began, .changed:
            self.imageView.tintColor = self.itemTintColor
            #if targetEnvironment(macCatalyst)
            NSCursor.pointingHand.set()
            #endif
        default:
            self.updateView()
            
            #if targetEnvironment(macCatalyst)
            NSCursor.arrow.set()
            #endif
        }
    }
}

@available(iOS 13.4, *)
extension TabBarButton: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        return UIPointerStyle(effect: .highlight(UITargetedPreview(view: self)))
    }
    
    func pointerInteraction(_ interaction: UIPointerInteraction, regionFor request: UIPointerRegionRequest, defaultRegion: UIPointerRegion) -> UIPointerRegion? {
        return defaultRegion
    }
}
