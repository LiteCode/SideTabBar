//
//  ViewController.swift
//  MasterDetail
//
//  Created by Vladislav Prusakov on 20.08.2019.
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
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
//        label.minimumScaleFactor = 0.8
//        return label
//    }()

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

    init(item: UITabBarItem, tabBar: TabBar, target: Any, action: Selector) {
        itemTintColor = tabBar.tintColor
        itemUnselectedTintColor = tabBar.unselectedItemTintColor ?? UIColor(white: 0.57, alpha: 1)

        super.init(frame: .zero)
        self.setup()
        self.addTarget(target, action: action, for: .touchUpInside)

        self.imageView.image = item.image?.withRenderingMode(.alwaysTemplate).withAlignmentRectInsets(item.imageInsets)

//        self.titleLabel.text = item.title
//        self.titleLabel.isHidden = item.title == nil
//        self.titleLabel.textAlignment = .center
        self.tabBarItem = item
    }

    private func setup() {

        self.updateTintColor()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        imageContainerView.addSubview(imageView)

//        let imageViewLeftAnchor = imageView.leftAnchor.constraint(equalTo: imageContainerView.leftAnchor, constant: 8)
//        imageViewLeftAnchor.priority = UILayoutPriority(rawValue: 800)

        imageContainerView.isUserInteractionEnabled = false
        imageView.isUserInteractionEnabled = false
        stackView.isUserInteractionEnabled = false
//        titleLabel.isUserInteractionEnabled = false
//        self.backgroundColor = .blue

        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
//            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor, constant: 10),
            imageView.widthAnchor.constraint(equalToConstant: 28),
            imageView.heightAnchor.constraint(equalToConstant: 28),
//            imageViewLeftAnchor
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

//        stackView.addArrangedSubview(titleLabel)
    }

    private func updateTintColor() {
        if isSelected {
            self.imageView.tintColor = itemTintColor
//            self.titleLabel.textColor = itemTintColor
        } else {
            self.imageView.tintColor = itemUnselectedTintColor
//            self.titleLabel.textColor = itemUnselectedTintColor
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TabBar: UITabBar {
    
    private weak var stackView: UIStackView!
    
    private var _items: [UITabBarItem]?
    
    override var items: [UITabBarItem]? {
        get { return _items }
        set { self.setItems(newValue, animated: false) }
    }
    
    private weak var selectedButton: TabBarButton? {
        didSet {
            oldValue?.isSelected = false
            self.selectedButton?.isSelected = true
        }
    }
    
    override var selectedItem: UITabBarItem? {
        willSet {
            self.selectedHandler?(newValue)
        }
    }
    
    init() {
        super.init(frame: .zero)
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    private var selectedHandler: ((UITabBarItem?) -> Void)?
    
    func setup() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
        
        self.stackView = stackView
    }
    
    override func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        let buttons = items?.compactMap { TabBarButton(item: $0, tabBar: self, target: self, action: #selector(onTabButtonPressed(_:)))} ?? []
        UIView.perform(usingAnimation: animated) {
            for subview in stackView.arrangedSubviews {
                stackView.removeArrangedSubview(subview)
            }

            for button in buttons {
                button.axis = .vertical
                stackView.addArrangedSubview(button)
            }

            stackView.addArrangedSubview(UIView())
        }
        
        self.selectedItem = items?.first
        self.selectedButton = buttons.first
        _items = items
    }
    
    @objc private func onTabButtonPressed(_ button: TabBarButton) {
        self.selectedItem = button.tabBarItem
        self.selectedButton = button
    }
    
    func onTabSelectedHandler(_ block: @escaping (UITabBarItem?) -> Void) {
        self.selectedHandler = block
    }
}


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

class TabBarViewController: UIViewController {
    
    private(set) lazy var viewControllers: [UIViewController] = []
    
    private weak var tabBar: UITabBar?
    
    private weak var detailContainerView: UIView!
    private weak var mainContainerView: UIView!
    
    private weak var detailWidthConstraint: NSLayoutConstraint?
    
    private enum Constants {
        static let detailPresentedWidth: CGFloat = 375
        static let detailHiddenWidth: CGFloat = 0
        static let width: CGFloat = 70
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mainContainerView = UIView()
        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        mainContainerView.backgroundColor = .red
        view.addSubview(mainContainerView)
        self.mainContainerView = mainContainerView
        
        let detailContainerView = UIVisualEffectView()
        detailContainerView.effect = UIBlurEffect(style: .systemChromeMaterial)
        detailContainerView.translatesAutoresizingMaskIntoConstraints = false
        detailContainerView.backgroundColor = .brown
        view.addSubview(detailContainerView)
        self.detailContainerView = detailContainerView
        
        let tabBar = TabBar()
        tabBar.onTabSelectedHandler { item in
            self.setVisibleDetailViewController(for: item)
        }
        
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        let detailWidthConstraint = detailContainerView.widthAnchor.constraint(equalToConstant: Constants.detailPresentedWidth)
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            tabBar.bottomAnchor.constraint(greaterThanOrEqualTo: view.bottomAnchor),
            tabBar.widthAnchor.constraint(equalToConstant: Constants.width),
            
            mainContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mainContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            detailWidthConstraint,
            detailContainerView.leftAnchor.constraint(equalTo: tabBar.rightAnchor),
            detailContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        self.additionalSafeAreaInsets.left = Constants.width
        
        self.detailWidthConstraint = detailWidthConstraint
        
        // MARK: - Mock
        
        let firstController = TestViewController(tabBarItem: UITabBarItem(title: nil, image: #imageLiteral(resourceName: "documents"), tag: 0))
        
        let secondController = TestViewController(tabBarItem: UITabBarItem(title: "TestAgain", image: #imageLiteral(resourceName: "finance"), tag: 1))
        
        self.setViewControllers([firstController, secondController], animated: false)
    }
    
    private var isDetailPresented: Bool {
        return self.detailWidthConstraint?.constant == Constants.detailPresentedWidth
    }
    
    private func setVisibleDetailViewController(for tabBarItem: UITabBarItem?) {
        
        let animator = UIViewPropertyAnimator(duration: 0.3, timingParameters: UICubicTimingParameters(animationCurve: .easeIn))
        
        if let item = tabBarItem {
            
            guard let viewControllerToShow = self.viewControllers.first(where: { $0.tabBarItem === item }) else { return }
            
            self.addChildViewController(viewControllerToShow, viewContainer: self.detailContainerView)
            
            
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = Constants.detailPresentedWidth
            

        } else {
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = Constants.detailHiddenWidth
        }
        
        animator.addAnimations {
            self.view.layoutIfNeeded()
        }
        
        animator.startAnimation()

    }
    
    func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        self.viewControllers = viewControllers ?? []
        
        let tabBarItems = self.viewControllers.compactMap { $0.tabBarItem }
        self.tabBar?.setItems(tabBarItems, animated: animated)
    }
    
}

extension UIViewController {
    
    func removeFromParentViewController() {
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    /// Adds a child view controller pinning it view to edges of viewContainer
    func addChildViewController(_ viewController: UIViewController, viewContainer: UIView) {
        self.addChildViewController(viewController) { (view) in
            viewContainer.insertSubview(view, at: 0)
            NSLayoutConstraint.activate([
                view.leftAnchor.constraint(equalTo: viewContainer.leftAnchor),
                view.rightAnchor.constraint(equalTo: viewContainer.rightAnchor),
                view.topAnchor.constraint(equalTo: viewContainer.topAnchor),
                view.bottomAnchor.constraint(equalTo: viewContainer.bottomAnchor)
            ])
        }
    }
    
    /// Adds a child view controller calling viewConfigurator to embed view
    func addChildViewController(_ viewController: UIViewController, viewConfigurator: (UIView) -> Void) {
        viewController.willMove(toParent: self)
        self.addChild(viewController)
        viewConfigurator(viewController.view)
        viewController.didMove(toParent: self)
    }
}

private class TestViewController: UIViewController {
    init(tabBarItem: UITabBarItem) {
        super.init(nibName: nil, bundle: nil)
        self.tabBarItem = tabBarItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
