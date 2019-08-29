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

        self.tabBarItem = item
    }

    private func setup() {

        self.updateTintColor()

        stackView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageContainerView.translatesAutoresizingMaskIntoConstraints = false

        imageContainerView.addSubview(imageView)

        imageContainerView.isUserInteractionEnabled = false
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

class TabBar: UITabBar {
    
    private weak var stackView: UIStackView!
    
    private var topItemsStackView: UIStackView!
    private var bottomItemsStackView: UIStackView!
    
    private var _topItems: [UITabBarItem]?
    private var _bottomItems: [UITabBarItem]?
    
    override var items: [UITabBarItem]? {
        get {
            var items = _topItems ?? []
            items.append(contentsOf: _bottomItems ?? [])
            return items
        }
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
            
            if newValue == nil {
                self.selectedButton = nil
            }
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
            stackView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor),
            stackView.leftAnchor.constraint(equalTo: self.leftAnchor),
            stackView.rightAnchor.constraint(equalTo: self.rightAnchor)
        ])
        
        self.stackView = stackView
        
        let topItemsStackView = UIStackView()
        topItemsStackView.axis = .vertical
        
        let bottomItemsStackView = UIStackView()
        bottomItemsStackView.axis = .vertical
        
        self.stackView.addArrangedSubview(topItemsStackView)
        self.stackView.addArrangedSubview(UIView())
        self.stackView.addArrangedSubview(bottomItemsStackView)
        
        self.topItemsStackView = topItemsStackView
        self.bottomItemsStackView = bottomItemsStackView
    }
    
    override func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        self.setItems(items, positioning: .automatic, animated: animated)
    }
    
    func setItems(_ items: [UITabBarItem]?, positioning: ItemPositioning, animated: Bool) {
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
            self._bottomItems = items
        default:
            self._topItems = items
        }
    }
    
    @objc private func onTabButtonPressed(_ button: TabBarButton) {
        if selectedButton === button {
            self.selectedItem = nil
            self.selectedButton = nil
        } else {
            self.selectedItem = button.tabBarItem
            self.selectedButton = button
        }
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

open class TabBarViewController: UIViewController {
    
    public var viewControllers: [UIViewController] {
        return topViewControllers + bottomViewControllers
    }
    
    public private(set) weak var tabBar: UITabBar!
    public private(set) weak var selectedViewController: UIViewController?
    
    private weak var detailContainerView: UIVisualEffectView!
    private weak var mainContainerView: UIView!
    private weak var overlayView: UIView!
    
    private weak var detailWidthConstraint: NSLayoutConstraint?
    
    private lazy var topViewControllers: [UIViewController] = []
    private lazy var bottomViewControllers: [UIViewController] = []
    
    private var isDetailPresented: Bool {
        return self.detailWidthConstraint?.constant == Constants.detailPresentedWidth
    }
    
    private enum Constants {
        static let detailPresentedWidth: CGFloat = 375
        static let detailHiddenWidth: CGFloat = 0
        static let width: CGFloat = 70
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()

        self.setup()
        
        // MARK: - Mock
        
        let firstController = TableTestViewController(tabBarItem: UITabBarItem(title: "Some new message", image: #imageLiteral(resourceName: "documents"), tag: 0))
        let secondController = TestViewController(tabBarItem: UITabBarItem(title: "TestAgain", image: #imageLiteral(resourceName: "finance"), tag: 1))
        self.setViewControllers([firstController, secondController], positioning: .bottom, animated: false)
        
        let firstController1 = TableTestViewController(tabBarItem: UITabBarItem(title: "Some new message", image: #imageLiteral(resourceName: "documents"), tag: 0))
        let secondController1 = TestViewController(tabBarItem: UITabBarItem(title: "TestAga32234in", image: #imageLiteral(resourceName: "finance"), tag: 1))
        self.setViewControllers([firstController1, secondController1], positioning: .top, animated: false)
        
        let mainController = TestViewController(tabBarItem: UITabBarItem(title: "TestAgain", image: #imageLiteral(resourceName: "finance"), tag: 1))
        self.showMasterViewController(mainController, sender: nil)
    }
    
    open func setViewControllers(_ viewControllers: [UIViewController]?, positioning: UITabBar.ItemPositioning = .automatic, animated: Bool) {
        guard let tabBar = self.tabBar as? TabBar else { return }
        
        let controllers = viewControllers ?? []
        
        switch positioning {
        case .bottom:
            self.bottomViewControllers = controllers
        default:
            self.topViewControllers = controllers
        }
        let tabBarItems = controllers.compactMap { $0.tabBarItem }
        tabBar.setItems(tabBarItems, positioning: positioning, animated: animated)
    }
    
    open func showMasterViewController(_ vc: UIViewController, sender: Any?) {
        self.addChildViewController(vc, viewContainer: self.mainContainerView)
    }
    
    // MARK: - Private
    
    private func setup() {
        
        let mainContainerView = UIView()
        mainContainerView.translatesAutoresizingMaskIntoConstraints = false
        //        mainContainerView.backgroundColor = .red
        view.addSubview(mainContainerView)
        self.mainContainerView = mainContainerView
        
        let detailContainerView = UIVisualEffectView()
        detailContainerView.effect = UIBlurEffect(style: .systemChromeMaterial)
        detailContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailContainerView)
        self.detailContainerView = detailContainerView
        
        let overlayView = UIView()
        overlayView.alpha = 0
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOverlayPressed(_:))))
        view.addSubview(overlayView)
        self.overlayView = overlayView
        
        let tabBar = TabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.onTabSelectedHandler { item in
            self.setVisibleDetailViewController(for: item)
        }
        
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        let detailWidthConstraint = detailContainerView.widthAnchor.constraint(equalToConstant: Constants.detailHiddenWidth)
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBar.widthAnchor.constraint(equalToConstant: Constants.width),
            
            mainContainerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            mainContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            mainContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            mainContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            detailWidthConstraint,
            detailContainerView.leftAnchor.constraint(equalTo: tabBar.rightAnchor),
            detailContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overlayView.leftAnchor.constraint(equalTo: detailContainerView.rightAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.additionalSafeAreaInsets.left = Constants.width
        
        self.detailWidthConstraint = detailWidthConstraint
    }
    
    private func setVisibleDetailViewController(for tabBarItem: UITabBarItem?) {
        
        let animator = UIViewPropertyAnimator(duration: 0.15, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
        
        if let item = tabBarItem {
            
            guard let viewControllerToShow = self.viewControllers.first(where: { $0.tabBarItem === item }) else { return }
            
            animator.addAnimations {
                self.overlayView.alpha = 1
            }
            
            self.selectedViewController?.removeFromParentViewController()
            self.addChildViewController(viewControllerToShow, viewContainer: self.detailContainerView.contentView)
            self.selectedViewController = viewControllerToShow
            
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = Constants.detailPresentedWidth
            
        } else {
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = Constants.detailHiddenWidth
            
            animator.addAnimations {
                self.overlayView.alpha = 0
            }
            
            animator.addCompletion { state in
                if state == .end {
                    self.selectedViewController?.removeFromParentViewController()
                    self.selectedViewController = nil
                }
            }
        }
        
        animator.addAnimations {
            self.view.layoutIfNeeded()
        }
        
        animator.startAnimation()

    }
    
    @objc private func onOverlayPressed(_ gesture: UITapGestureRecognizer) {
        self.tabBar.selectedItem = nil
    }
}

public extension UITabBar.ItemPositioning {
    static let top = UITabBar.ItemPositioning(rawValue: 12)!
    static let bottom = UITabBar.ItemPositioning(rawValue: 13)!
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

// MARK: - Test Controllers

private class TestViewController: UIViewController {
    
    private weak var label: UILabel!
    
    init(tabBarItem: UITabBarItem) {
        super.init(nibName: nil, bundle: nil)
        self.tabBarItem = tabBarItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel()
        label.textColor = .black
        label.text = self.tabBarItem.title
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        self.view.addSubview(label)
        self.label = label
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
            label.leftAnchor.constraint(equalTo: self.view.leftAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private class TableTestViewController: UITableViewController {
    
    init(tabBarItem: UITabBarItem) {
        super.init(nibName: nil, bundle: nil)
        self.tabBarItem = tabBarItem
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "identifier") ?? UITableViewCell(style: .default, reuseIdentifier: "identifier")
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = .clear
        cell.textLabel?.text = "Some index \(indexPath.row)"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
