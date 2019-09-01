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

    init(item: UITabBarItem, tabBar: SideTabBar, target: Any, action: Selector) {
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

public protocol SideTabBarDelegate: AnyObject {
    func tabBar(_ tabBar: SideTabBar, shouldSelect tabBarItem: UITabBarItem) -> Bool
    func tabBar(_ tabBar: SideTabBar, didSelect tabBarItem: UITabBarItem)
}

public extension SideTabBarDelegate {
    func tabBar(_ tabBar: SideTabBar, shouldSelect tabBarItem: UITabBarItem) -> Bool { return true }
    func tabBar(_ tabBar: SideTabBar, didSelect tabBarItem: UITabBarItem) {}
}

open class SideTabBar: UIView {
    
    public enum ItemPositioning {
        case automatic
        case top
        case bottom
    }
    
    private weak var stackView: UIStackView!
    private weak var visualEffectView: UIVisualEffectView!
    
    var visualEffect: UIVisualEffect = UIBlurEffect(style: .systemChromeMaterial) {
        didSet {
            self.visualEffectView.effect = self.visualEffect
        }
    }
    
    private var topItemsStackView: UIStackView!
    private var bottomItemsStackView: UIStackView!
    private var verticalSeparatorView: UIView!
    
    open weak var delegate: SideTabBarDelegate?
    open var unselectedItemTintColor: UIColor?
    
    private var _topItems: [UITabBarItem]?
    private var _bottomItems: [UITabBarItem]?
    
    open var items: [UITabBarItem]? {
        get {
            var items = _topItems ?? []
            items.append(contentsOf: _bottomItems ?? [])
            return items
        }
        set { self.setItems(newValue, animated: false) }
    }
    
    open var itemSpacing: CGFloat = 0 {
        didSet {
            self.topItemsStackView.spacing = self.itemSpacing
            self.bottomItemsStackView.spacing = self.itemSpacing
        }
    }
    
    private weak var selectedButton: TabBarButton? {
        didSet {
            oldValue?.isSelected = false
            self.selectedButton?.isSelected = true
        }
    }
    
    open var selectedItem: UITabBarItem? {
        willSet {
            self.selectedHandler?(newValue)
            
            if newValue == nil {
                self.selectedButton = nil
            }
        }
    }
    
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
    
    private var selectedHandler: ((UITabBarItem?) -> Void)?
    
    private func setup() {
        
        self.backgroundColor = .clear
        
        #if targetEnvironment(macCatalyst)
        self.visualEffect = UIBlurEffect.makeBlurThroughEffect(style: .throughWhileActive)
        #endif
        
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
    
    open func setItems(_ items: [UITabBarItem]?, animated: Bool) {
        self.setItems(items, positioning: .automatic, animated: animated)
    }
    
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
            self._bottomItems = items
        default:
            self._topItems = items
        }
    }
    
    @objc private func onTabButtonPressed(_ button: TabBarButton) {
        guard let tabBarItem = button.tabBarItem else { return }
        let shouldSelect = self.delegate?.tabBar(self, shouldSelect: tabBarItem) ?? true
        
        guard shouldSelect else { return }
        
        self.delegate?.tabBar(self, didSelect: tabBarItem)
        
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

extension NSLayoutConstraint {
        @IBInspectable var pxConstant: CGFloat {
        get { return self.constant * UIScreen.main.scale }
        set { self.constant = newValue / UIScreen.main.scale }
    }
}

public protocol TabBarViewControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: UIViewController, shouldSelect viewController: UIViewController) -> Bool
}

extension TabBarViewControllerDelegate {
    func tabBarController(_ tabBarController: UIViewController, shouldSelect viewController: UIViewController) -> Bool { return true }
}

open class TabBarViewController: UIViewController {
    
    public enum DisplayMode {
        case menuHidden
        case allVisible
    }
    
    public var viewControllers: [UIViewController] {
        return topViewControllers + bottomViewControllers
    }
    
    open var displayMode: DisplayMode = .menuHidden {
        didSet {
            self.updateViewState()
        }
    }
    
    /// The index of the view controller associated with the currently selected tab item.
    ///
    /// If the itam unselected, this property contains the value `NSNotFound`
    open var selectedIndex: Int {
        get {
            guard let index = viewControllers.firstIndex(where: { $0 === self.selectedViewController }) else { return NSNotFound }
            return index
        }
        
        set {
            guard let vc = viewControllers[safe: newValue] else { return }
            self.setVisibleDetailViewController(for: vc.tabBarItem)
        }
    }
    
    public weak var delegate: TabBarViewControllerDelegate?
    
    public private(set) weak var tabBar: SideTabBar!
    public private(set) weak var selectedViewController: UIViewController?
    public private(set) weak var contentViewController: UIViewController?
    
    /// A Boolean indicating whether the underlying content is obscured during a menu presented
    ///
    /// The default value of this property is true.
    open var obscuresBackgroundDuringPresentation: Bool = false {
        didSet {
            self.updateOverlayView()
        }
    }
    
    open var backgroundVisualEffect: UIVisualEffect = UIBlurEffect(style: .systemChromeMaterial) {
        didSet {
            self.detailContainerView.effect = self.backgroundVisualEffect
            self.tabBar.visualEffect = self.backgroundVisualEffect
        }
    }
    
    // MARK: Views
    private weak var detailContainerView: UIVisualEffectView!
    private weak var contentContainerView: UIView!
    private weak var overlayView: UIView!
    
    // MARK: Constraints
    private weak var detailWidthConstraint: NSLayoutConstraint?
    private weak var tabBarWidthConstraint: NSLayoutConstraint?
    private var detailRightConstraint: NSLayoutConstraint!
    
    // MARK: Other
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
        self.showContentViewController(UINavigationController(rootViewController: mainController), sender: nil)
    }
    
    open func setViewControllers(_ viewControllers: [UIViewController]?, positioning: SideTabBar.ItemPositioning = .automatic, animated: Bool) {
        
        let controllers = viewControllers ?? []
        
        switch positioning {
        case .bottom:
            self.bottomViewControllers = controllers
        default:
            self.topViewControllers = controllers
        }
        let tabBarItems = controllers.compactMap { $0.tabBarItem }
        self.tabBar.setItems(tabBarItems, positioning: positioning, animated: animated)
    }
    
    open func showContentViewController(_ vc: UIViewController, sender: Any?) {
        self.contentViewController?.removeFromParentViewController()
        self.addChildViewController(vc, viewContainer: self.contentContainerView)
        self.contentViewController = vc
    }
    
    // MARK: - Private
    
    private func setup() {
        
        let contentContainerView = UIView()
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentContainerView)
        self.contentContainerView = contentContainerView
        
        let detailContainerView = UIVisualEffectView()
        
        #if targetEnvironment(macCatalyst)
        self.backgroundVisualEffect = UIBlurEffect.makeBlurThroughEffect(style: .throughWhileActive)
        #endif
        
        detailContainerView.effect = self.backgroundVisualEffect
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
        
        self.updateOverlayView()
        
        let tabBar = SideTabBar()
//        tabBar.delegate = self
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.onTabSelectedHandler { item in
            self.setVisibleDetailViewController(for: item)
        }
        
        let screenGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onLeftEdgeScreenGesture(_:)))
        screenGesture.edges = .left
        contentContainerView.addGestureRecognizer(screenGesture)
        
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        let detailWidthConstraint = detailContainerView.widthAnchor.constraint(equalToConstant: Constants.detailHiddenWidth)
        let tabBarWidthConstraint = tabBar.widthAnchor.constraint(equalToConstant: Constants.width)
        let detailRightConstraint = detailContainerView.rightAnchor.constraint(equalTo: contentContainerView.leftAnchor)
        let contentContainerLeftConstraint = contentContainerView.leftAnchor.constraint(equalTo: view.leftAnchor)
        contentContainerLeftConstraint.priority = UILayoutPriority(rawValue: 800)
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBar.leftAnchor.constraint(equalTo: view.leftAnchor),
            tabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarWidthConstraint,
            
            contentContainerLeftConstraint,
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            detailWidthConstraint,
            detailContainerView.leftAnchor.constraint(equalTo: tabBar.rightAnchor),
            detailContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            detailContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            overlayView.leftAnchor.constraint(equalTo: detailContainerView.rightAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.tabBarWidthConstraint = tabBarWidthConstraint
        self.detailWidthConstraint = detailWidthConstraint
        self.detailRightConstraint = detailRightConstraint
        
        self.updateViewState()
    }
    
    private func updateOverlayView() {
        self.overlayView.backgroundColor = obscuresBackgroundDuringPresentation ? UIColor.black.withAlphaComponent(0.3) : .clear
    }
    
    private func updateViewState() {
        if self.isIphoneHSizeClass {
            self.additionalSafeAreaInsets.left = 0
//            self.detailRightConstraint.isActive = true
        } else {
            self.additionalSafeAreaInsets.left = Constants.width
//            self.detailRightConstraint.isActive = false
        }
        
        
        
        switch self.displayMode {
        case .allVisible:
            self.detailRightConstraint.isActive = true
            self.detailWidthConstraint?.constant = Constants.detailPresentedWidth
        case .menuHidden:
            self.detailWidthConstraint?.constant = self.selectedViewController == nil ? Constants.detailHiddenWidth :Constants.detailPresentedWidth
            self.detailRightConstraint.isActive = false
        }
        
        UIView.animate(withDuration: 0.15) {
            self.view.layoutIfNeeded()
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        self.updateViewState()
    }
    
    private var isIphoneHSizeClass: Bool {
        return self.traitCollection.horizontalSizeClass == .compact && self.view.frame.width <= Constants.detailPresentedWidth
    }
    
    @objc private func onLeftEdgeScreenGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard self.isIphoneHSizeClass else { return }
        
    }
    
    private func setVisibleDetailViewController(for tabBarItem: UITabBarItem?) {
        
        let animator = UIViewPropertyAnimator(duration: 0.15, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
        
        if let item = tabBarItem {
            
            guard let index = self.viewControllers.firstIndex(where: { $0.tabBarItem === item }) else { return }
            let viewControllerToShow = self.viewControllers[index]
            
            if self.displayMode == .menuHidden {
                animator.addAnimations {
                    self.overlayView.alpha = 1
                }
            }
            
            self.selectedViewController?.removeFromParentViewController()
            self.addChildViewController(viewControllerToShow, viewContainer: self.detailContainerView.contentView)
            self.selectedViewController = viewControllerToShow
            
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = Constants.detailPresentedWidth
            
        } else {
            self.view.layoutIfNeeded()
            self.detailWidthConstraint?.constant = self.displayMode == .menuHidden ? Constants.detailHiddenWidth : Constants.detailPresentedWidth
            
            animator.addAnimations {
                self.overlayView.alpha = 0
            }
            
            if self.displayMode == .menuHidden {
                animator.addCompletion { state in
                    if state == .end {
                        self.selectedViewController?.removeFromParentViewController()
                        self.selectedViewController = nil
                    }
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
//
//extension TabBarViewController: SideTabBarDelegate {
//    func tabBar(_ tabBar: SideTabBar, shouldSelect tabBarItem: UITabBarItem) -> Bool {
//        guard let first = self.viewControllers.first(where: { $0.tabBarItem === tabBarItem }) else { return false }
//        return self.delegate?.tabBarController(self, shouldSelect: first) ?? true
//    }
//}

public extension UITabBar.ItemPositioning {
    static let top = UITabBar.ItemPositioning(rawValue: 12)!
    static let bottom = UITabBar.ItemPositioning(rawValue: 13)!
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


// MARK: - Test Controllers

private class TestViewController: UIViewController {
    
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(onDisplayModePressed))
        
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
    
    private var isAllVisible: Bool {
        return self.sideTabBarController?.displayMode == .allVisible
    }
    
    @objc func onDisplayModePressed() {
        let isAllVisible = self.isAllVisible
        self.sideTabBarController?.displayMode = isAllVisible ? .menuHidden : .allVisible
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
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let viewController = TestViewController(name: "Some index \(indexPath.row)")
        self.sideTabBarController?.showContentViewController(UINavigationController(rootViewController: viewController), sender: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SplitTestVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem
        self.splitViewController?.primaryBackgroundStyle = .sidebar
        self.splitViewController?.preferredDisplayMode = .primaryOverlay
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
