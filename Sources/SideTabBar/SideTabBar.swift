//
//  SideTabBar.swift
//  MasterDetail
//
//  Created by Vladislav Prusakov on 02.09.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

import UIKit

/// The SideTabBarDelegate protocol defines optional methods for a delegate of a SideTabBar object.
public protocol SideTabBarDelegate: AnyObject {
    /// Called to the delegate when should the user selects a tab bar item.
    func tabBar(_ tabBar: SideTabBar, shouldSelect tabBarItem: UITabBarItem) -> Bool
    
    /// Sent to the delegate when the user selects a tab bar item.
    func tabBar(_ tabBar: SideTabBar, didSelect tabBarItem: UITabBarItem)
}

public extension SideTabBarDelegate {
    func tabBar(_ tabBar: SideTabBar, shouldSelect tabBarItem: UITabBarItem) -> Bool { return true }
    func tabBar(_ tabBar: SideTabBar, didSelect tabBarItem: UITabBarItem) {}
}

/// A control that displays one or more buttons in a tab bar for selecting between different subtasks, views, or modes in an app.
open class SideTabBar: UIView {
    
    /// Constants
    public enum ItemPositioning {
        case automatic
        case top
        case bottom
    }
    
    // MARK: - Public properties.
    
    /// The tab bar’s delegate object.
    open weak var delegate: SideTabBarDelegate?
    
    /// The tint color to apply to unselected tabs.
    open var unselectedItemTintColor: UIColor?
    
    /// The items displayed by the tab bar.
    open var items: [UITabBarItem]? {
        get {
            var items = _topItems ?? []
            items.append(contentsOf: _bottomItems ?? [])
            return items
        }
        set { self.setItems(newValue, animated: false) }
    }
    
    /// The amount of space (in points) to use between tab bar items.
    open var itemSpacing: CGFloat = 0 {
        didSet {
            self.topItemsStackView.spacing = self.itemSpacing
            self.bottomItemsStackView.spacing = self.itemSpacing
        }
    }
    
    /// The currently selected item on the tab bar.
    open var selectedItem: UITabBarItem? {
        willSet {
            self.selectedHandler?(newValue)
            
            if let value = newValue {
                self.selectedButton = self.buttons.first { $0.tabBarItem === value }
            } else {
                self.selectedButton = nil
            }
        }
    }
    
    // MARK: - Private properties.
    
    private weak var stackView: UIStackView!
    private weak var visualEffectView: UIVisualEffectView!
    
    var visualEffect: UIVisualEffect = UIBlurEffect(style: .systemChromeMaterial) {
        didSet {
            self.visualEffectView?.effect = self.visualEffect
        }
    }
    
    private var topItemsStackView: UIStackView!
    private var bottomItemsStackView: UIStackView!
    private var verticalSeparatorView: UIView!
    
    var canDeselect = true
    
    private var _topItems: [UITabBarItem]?
    private var _bottomItems: [UITabBarItem]?
    
    private var _topButtons: [TabBarButton]?
    private var _bottomButtons: [TabBarButton]?
    
    private var buttons: [TabBarButton] {
        var items = _topButtons ?? []
        items.append(contentsOf: _bottomButtons ?? [])
        return items
    }
    
    private weak var selectedButton: TabBarButton? {
        didSet {
            oldValue?.isSelected = false
            self.selectedButton?.isSelected = true
        }
    }
    
    // MARK: - Public
    
    public init() {
        super.init(frame: .zero)
        self.setup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    /// Sets the items on the tab bar, optionally animating any changes into position.
    /// - Parameter items: The array of UITabBarItem objects to display.
    /// - Parameter animated: A Boolean indicating whether changes should be animated. Specify true to animate changes or false to display the new items without animations. .
    open func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        self.setItems(items, positioning: .automatic, animated: animated)
    }
    
    /// Sets the items on the tab bar, optionally animating any changes into position.
    /// - Parameter items: The array of UITabBarItem objects to display.
    /// - Parameter positioning: The position where items should locate.
    /// - Parameter animated: A Boolean indicating whether changes should be animated. Specify true to animate changes or false to display the new items without animations. .
    open func setItems(_ items: [UITabBarItem]?, positioning: ItemPositioning, animated: Bool) {
        let buttons = items?.compactMap { TabBarButton(item: $0, tabBar: self, target: self, action: #selector(onTabButtonPressed(_:))) } ?? []
        
        guard let stackView = positioning == .bottom ? self.bottomItemsStackView : self.topItemsStackView else { return }
        
        UIView.perform(usingAnimation: animated) {
            for subview in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(subview)
            }

            for button in buttons {
                button.axis = .vertical
                stackView.addArrangedSubview(button)
            }
        }
        
        switch positioning {
        case .bottom:
            self._bottomButtons = buttons
            self._bottomItems = items
        default:
            self._topButtons = buttons
            self._topItems = items
        }
    }
    
    // MARK: - Private
    
    private var selectedHandler: ((UITabBarItem?) -> Void)?
    
    private func setup() {
        self.backgroundColor = .clear
        
        let visualEffectView = UIVisualEffectView()
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.effect = self.visualEffect
        self.addSubview(visualEffectView)
        self.visualEffectView = visualEffectView
        
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        visualEffectView.contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: self.topAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            visualEffectView.leftAnchor.constraint(equalTo: self.leftAnchor),
            visualEffectView.rightAnchor.constraint(equalTo: self.rightAnchor),
            
            stackView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: visualEffectView.contentView.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: visualEffectView.contentView.rightAnchor)
        ])
        
        self.stackView = stackView
        
        let topItemsStackView = UIStackView()
        topItemsStackView.axis = .vertical
        topItemsStackView.spacing = self.itemSpacing
        
        let bottomItemsStackView = UIStackView()
        bottomItemsStackView.spacing = self.itemSpacing
        bottomItemsStackView.axis = .vertical
        
        self.stackView.addArrangedSubview(topItemsStackView)
        self.stackView.addArrangedSubview(UIView())
        self.stackView.addArrangedSubview(bottomItemsStackView)
        
        self.topItemsStackView = topItemsStackView
        self.bottomItemsStackView = bottomItemsStackView
    }
    
    @objc private func onTabButtonPressed(_ button: TabBarButton) {
        guard let tabBarItem = button.tabBarItem else { return }
        let shouldSelect = self.delegate?.tabBar(self, shouldSelect: tabBarItem) ?? true
        
        guard shouldSelect else { return }
        
        self.delegate?.tabBar(self, didSelect: tabBarItem)
        
        if selectedButton === button {
            if canDeselect {
                self.selectedItem = nil
            }
        } else {
            self.selectedItem = button.tabBarItem
        }
    }
    
    func onTabSelectedHandler(_ block: @escaping (UITabBarItem?) -> Void) {
        self.selectedHandler = block
    }
}
