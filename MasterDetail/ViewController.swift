//
//  ViewController.swift
//  MasterDetail
//
//  Created by Vladislav Prusakov on 20.08.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

import UIKit

// What i should do:
// 1. Make OverlayView: Blur, background color and touch and close [ ]
// 2. Make preferredDisplayMode [X]
// 3. Make handle that primary modal dismissed [X]
// 4. Make swipable tab bar for iPhone devices [X]
// 5. Unselect tab if primary modal controller was dismissed [X]
// 6. Add flow separator for change size between primary and master views

public protocol SideTabBarViewControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: SideTabBarViewController, shouldSelect viewController: UIViewController) -> Bool
    func tabBarController(_ tabBarController: SideTabBarViewController, willPresent primaryViewController: UIViewController, presentationStyle: SideTabBarViewController.PrimaryPresentationStyle)
    func tabBarController(_ tabBarController: SideTabBarViewController, didDismiss primaryViewController: UIViewController)
    
    func tabBarController(_ tabBarController: SideTabBarViewController, didUpdateBarButtonItemForDisplayMode: SideTabBarViewController.DisplayMode) -> UIImage?
    
    func tabBarController(_ tabBarController: SideTabBarViewController, willChangeTo displayMode: SideTabBarViewController.DisplayMode)
}

public extension SideTabBarViewControllerDelegate {
    func tabBarController(_ tabBarController: SideTabBarViewController, shouldSelect viewController: UIViewController) -> Bool { return true }
    func tabBarController(_ tabBarController: SideTabBarViewController, willPresent primaryViewController: UIViewController, presentationStyle: SideTabBarViewController.PrimaryPresentationStyle) { }
    func tabBarController(_ tabBarController: SideTabBarViewController, didDismiss primaryViewController: UIViewController) { }
    func tabBarController(_ tabBarController: SideTabBarViewController, willChangeTo displayMode: SideTabBarViewController.DisplayMode) { }
}

open class SideTabBarViewController: UIViewController {
    
    public enum PrimaryPresentationStyle {
        case modal
        case primary
    }
    
    public enum DisplayMode {
        case primaryHidden
        case primaryOverlay
        case primaryModal
        case allVisible
    }
    
    public var viewControllers: [UIViewController] {
        return topViewControllers + bottomViewControllers
    }
    
    open private(set) var displayMode: DisplayMode = .primaryHidden {
        willSet {
            self.delegate?.tabBarController(self, willChangeTo: newValue)
        }
        didSet {
            self.updateDisplayModeBarButtonItem()
        }
    }
    
    open var prefferedDisplayMode: DisplayMode = .primaryOverlay {
        didSet {
            self.updateViewState()
        }
    }
    
    open var tabBarWidth: CGFloat = 70 {
        didSet {
            self.tabBarWidthConstraint?.constant = self.tabBarWidth
            self.updateViewState()
        }
    }
    
    open var minimumPrimaryColumnWidth: CGFloat = 375
    open var maximumPrimaryColumnWidth: CGFloat = 375
    
    open var primaryWidth: CGFloat = 375 {
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
            self.setVisiblePrimaryViewController(for: vc.tabBarItem)
        }
    }
    
    public weak var delegate: SideTabBarViewControllerDelegate?
    
    public private(set) weak var tabBar: SideTabBar!
    public private(set) weak var selectedViewController: UIViewController?
    public private(set) weak var contentViewController: UIViewController?
    
    /// A Boolean indicating whether the underlying content is obscured during a menu presented
    ///
    /// The default value of this property is true.
    open var obscuresBackgroundDuringPresentation: Bool = true {
        didSet {
            self.updateOverlayView()
        }
    }
    
    open var backgroundVisualEffect: UIVisualEffect = UIBlurEffect(style: .systemChromeMaterial) {
        didSet {
            self.detailContainerView?.effect = self.backgroundVisualEffect
            self.tabBar?.visualEffect = self.backgroundVisualEffect
        }
    }
    
    open private(set) lazy var displayModeButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .done, target: self, action: #selector(onDisplayModeButtonItemPressed(barButtonItem:)))
    }()
    
    // MARK: Views
    private weak var detailContainerView: UIVisualEffectView!
    private weak var contentContainerView: UIView!
    private weak var overlayView: OverlayView!
    private weak var separatorView: UIView!
    
    // MARK: Constraints
    private var detailWidthConstraint: NSLayoutConstraint?
    private weak var tabBarWidthConstraint: NSLayoutConstraint?
    private var tabBarLeftConstraint: NSLayoutConstraint!
    private var detailRightConstraint: NSLayoutConstraint!
    
    // MARK: Other
    private lazy var topViewControllers: [UIViewController] = []
    private lazy var bottomViewControllers: [UIViewController] = []
    private var previousSelectedIndex: Int = 0
    
    open var isCollapsed: Bool {
        return self.detailWidthConstraint?.constant != Constants.detailHiddenWidth
    }
    
    private var isTabBarPresented: Bool = false
    
    private enum Constants {
        static let detailHiddenWidth: CGFloat = 0
        static let animationDuration: TimeInterval = 0.15
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
        
        let separatorView = UIView()
        separatorView.backgroundColor = UIColor.barHairlineColor
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(separatorView)
        self.separatorView = separatorView
        
        let detailContainerView = UIVisualEffectView()
        
        // TODO: Remove or change
        #if targetEnvironment(macCatalyst)
        self.backgroundVisualEffect = UIBlurEffect.makeBlurThroughEffect(style: .throughWhileActive)
        #endif
        
        detailContainerView.effect = self.backgroundVisualEffect
        detailContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailContainerView)
        self.detailContainerView = detailContainerView
        
        let overlayView = OverlayView()
        overlayView.alpha = 0
        overlayView.backgroundColor = UIColor.barHairlineColor
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onOverlayPressed(_:))))
        view.addSubview(overlayView)
        self.overlayView = overlayView
        
        self.updateOverlayView()
        
        let tabBar = SideTabBar()
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        
        tabBar.onTabSelectedHandler { [weak self] item in
            self?.setVisiblePrimaryViewController(for: item)
        }
        
        let screenGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(onLeftEdgeScreenGesture(_:)))
        screenGesture.edges = .left
        contentContainerView.addGestureRecognizer(screenGesture)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onTabBarPanGestire(_:)))
        tabBar.addGestureRecognizer(panGesture)
        
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        let detailWidthConstraint = detailContainerView.widthAnchor.constraint(equalToConstant: Constants.detailHiddenWidth)
        let tabBarWidthConstraint = tabBar.widthAnchor.constraint(equalToConstant: self.tabBarWidth)
        let detailRightConstraint = detailContainerView.rightAnchor.constraint(equalTo: contentContainerView.leftAnchor)
        let contentContainerLeftConstraint = contentContainerView.leftAnchor.constraint(equalTo: view.leftAnchor)
        contentContainerLeftConstraint.priority = UILayoutPriority(rawValue: 800)
        
        let tabBarLeftConstraint = tabBar.leftAnchor.constraint(equalTo: view.leftAnchor)
        
        NSLayoutConstraint.activate([
            tabBar.topAnchor.constraint(equalTo: view.topAnchor),
            tabBarLeftConstraint,
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
            
            separatorView.leftAnchor.constraint(equalTo: detailContainerView.rightAnchor),
            separatorView.topAnchor.constraint(equalTo: view.topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            
            overlayView.leftAnchor.constraint(equalTo: overlayView.rightAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.tabBarLeftConstraint = tabBarLeftConstraint
        self.tabBarWidthConstraint = tabBarWidthConstraint
        self.detailWidthConstraint = detailWidthConstraint
        self.detailRightConstraint = detailRightConstraint
        
        self.updateViewState()
    }
    
    private func updateOverlayView() {
        self.overlayView.backgroundColor = obscuresBackgroundDuringPresentation ? UIColor.barHairlineColor : .clear
    }
    
    private func updateViewState() {
        if self.isIPhoneHorizontalSizeClass {
            self.additionalSafeAreaInsets.left = 0
            self.detailRightConstraint.isActive = false
            self.setTabBarVisible(false, animated: false)
            self.tabBar.canDeselect = true
            self.detailWidthConstraint?.constant = Constants.detailHiddenWidth
        } else {
            self.setTabBarVisible(true, animated: false)
            self.additionalSafeAreaInsets.left = self.tabBarWidth
            
            let displayMode = self.posibleDisplayMode(from: self.prefferedDisplayMode)
            
            switch displayMode {
            case .allVisible:
                self.tabBar.canDeselect = false
                self.detailRightConstraint.isActive = true
            case .primaryHidden, .primaryOverlay, .primaryModal:
                self.tabBar.canDeselect = true
                self.detailRightConstraint.isActive = false
            }
            
            self.detailWidthConstraint?.constant = (self.selectedViewController == nil) ? Constants.detailHiddenWidth : self.primaryWidth
        }
        
        self.updateDisplayModeBarButtonItem()
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func posibleDisplayMode(from preferredDisplayMode: DisplayMode) -> DisplayMode {
        if self.isIPhoneHorizontalSizeClass {
            return preferredDisplayMode != .primaryHidden ? .primaryModal : .primaryHidden
        } else {
            switch preferredDisplayMode {
            case .allVisible:
                if self.view.frame.width <= self.primaryWidth {
                    return .primaryOverlay
                } else {
                    return .allVisible
                }
            default:
                return preferredDisplayMode
            }
        }
    }
    
    private func updateDisplayModeBarButtonItem() {
        
        if let delegate = self.delegate, let image = delegate.tabBarController(self, didUpdateBarButtonItemForDisplayMode: self.displayMode) {
            self.displayModeButtonItem.image = image
        } else {
            switch displayMode {
            case .allVisible:
                self.displayModeButtonItem.image = UIImage(systemName: "arrow.up.left.and.arrow.down.right")
            case .primaryOverlay:
                self.displayModeButtonItem.image = UIImage(systemName: "chevron.left")
            case .primaryHidden:
                self.displayModeButtonItem.image = self.isIPhoneHorizontalSizeClass ? UIImage(systemName: "chevron.up") : UIImage(systemName: "sidebar.left")
            case .primaryModal:
                self.displayModeButtonItem.image = nil
            }
        }
    }
    
    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.updateViewState()
            self.updateSelectedViewController()
        }
    }
    
    private func updateSelectedViewController() {
        guard let viewControllerToShow = self.selectedViewController else { return }
        if self.isIPhoneHorizontalSizeClass {
            viewControllerToShow.removeFromParentViewController()
            self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .modal)
            viewControllerToShow.presentationController?.delegate = self
            self.present(viewControllerToShow, animated: false)
        } else {
            self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .primary)
            viewControllerToShow.dismiss(animated: false, completion: {
                self.addChildViewController(viewControllerToShow, viewContainer: self.detailContainerView.contentView)
            })
        }
    }
    
    private func setTabBarVisible(_ visible: Bool, animated: Bool) {
        if visible {
            self.tabBarLeftConstraint.constant = 0
            self.isTabBarPresented = true
        } else {
            guard self.isIPhoneHorizontalSizeClass else { return }
            self.tabBarLeftConstraint.constant = -self.tabBarWidth
            self.isTabBarPresented = false
        }
        
        if animated {
            UIView.animate(withDuration: Constants.animationDuration) {
                self.view.layoutIfNeeded()
            }
        } else {
            self.view.layoutIfNeeded()
        }
    }
    
    private var isIPhoneHorizontalSizeClass: Bool {
        return self.traitCollection.horizontalSizeClass == .compact && self.view.frame.width <= self.primaryWidth
    }
    
    @objc private func onLeftEdgeScreenGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        guard self.isIPhoneHorizontalSizeClass && !self.isTabBarPresented else { return }
        
        let translation = gesture.translation(in: gesture.view)
        
        switch gesture.state {
        case .failed, .cancelled, .ended:
            if translation.x > 0 {
                self.isTabBarPresented = true
                self.tabBarLeftConstraint.constant = 0
            }
        default:
            if translation.x > 0 && translation.x < self.tabBarWidth {
                self.tabBarLeftConstraint.constant = -self.tabBarWidth + translation.x
            }
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func onTabBarPanGestire(_ gesture: UIPanGestureRecognizer) {
        guard self.isIPhoneHorizontalSizeClass && self.isTabBarPresented else { return }
        let translation = gesture.translation(in: gesture.view)
        
        switch gesture.state {
        case .failed, .cancelled, .ended:
            if translation.x < 0 {
                self.isTabBarPresented = false
                self.tabBarLeftConstraint.constant = -self.tabBarWidth
            }
        default:
            if translation.x > -self.tabBarWidth && translation.x < 0 {
                self.tabBarLeftConstraint.constant = 0 + translation.x
            }
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setVisiblePrimaryViewController(for tabBarItem: UITabBarItem?) {
        if let item = tabBarItem {
            guard let index = self.viewControllers.firstIndex(where: { $0.tabBarItem === item }) else { return }
            self.previousSelectedIndex = index
            let viewControllerToShow = self.viewControllers[index]
            
            let displayMode = self.posibleDisplayMode(from: self.prefferedDisplayMode)
            self.showPrimaryViewController(viewControllerToShow, for: displayMode)
        } else {
            self.detailWidthConstraint?.constant = Constants.detailHiddenWidth
            
            let animator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
            
            animator.addAnimations {
                self.overlayView.alpha = 0
                self.view.layoutIfNeeded()
            }
            
            animator.addCompletion { position in
                if position == .end {
                    self.selectedViewController?.removeFromParentViewController()
                    self.selectedViewController = nil
                    self.displayMode = .primaryHidden
                }
            }

            animator.startAnimation()
        }
    }
    
    @objc private func onOverlayPressed(_ gesture: UITapGestureRecognizer) {
        self.tabBar.selectedItem = nil
    }
    
    private func showPrimaryViewController(_ viewController: UIViewController, for displayMode: DisplayMode) {
        
        if self.isIPhoneHorizontalSizeClass {
            self.delegate?.tabBarController(self, willPresent: viewController, presentationStyle: .modal)
            viewController.presentationController?.delegate = self
            self.present(viewController, animated: true)
            self.setTabBarVisible(false, animated: true)
            self.displayMode = .primaryModal
        } else {
            
            let animator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
            
            switch displayMode {
            case .allVisible:
                self.tabBar.canDeselect = false
                self.detailRightConstraint.isActive = true
                self.selectedViewController?.removeFromParentViewController()
                self.addChildViewController(viewController, viewContainer: self.detailContainerView.contentView)
                self.view.layoutIfNeeded()
                
                animator.addAnimations {
                    self.overlayView.alpha = 0
                }
                
                self.delegate?.tabBarController(self, willPresent: viewController, presentationStyle: .primary)
                self.displayMode = .allVisible
                self.detailWidthConstraint?.constant = self.primaryWidth
            case .primaryModal, .primaryOverlay, .primaryHidden:
                self.tabBar.canDeselect = true
                self.selectedViewController?.removeFromParentViewController()
                self.addChildViewController(viewController, viewContainer: self.detailContainerView.contentView)
                self.view.layoutIfNeeded()
                
                self.detailWidthConstraint?.constant = self.primaryWidth
                
                animator.addAnimations {
                    self.overlayView.alpha = 1
                }
                
                self.displayMode = .primaryOverlay
                self.delegate?.tabBarController(self, willPresent: viewController, presentationStyle: .primary)
            }
            
            animator.addAnimations {
                self.view.layoutIfNeeded()
            }
            
            animator.startAnimation()
        }
        
        self.selectedViewController = viewController
    }
    
    private func hidePrimaryViewController() {
        self.displayMode = .primaryHidden
    }
    
    @objc func onDisplayModeButtonItemPressed(barButtonItem: UIBarButtonItem) {
        if self.displayMode == .primaryHidden || self.selectedViewController == nil {
            let viewControllerToShow = viewControllers[self.previousSelectedIndex]
            self.tabBar.selectedItem = viewControllerToShow.tabBarItem
        } else {
            self.tabBar.selectedItem = nil
        }
    }
}

extension SideTabBarViewController: UIAdaptivePresentationControllerDelegate {
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.tabBarController(self, didDismiss: presentationController.presentedViewController)
        self.tabBar.selectedItem = nil
        self.selectedViewController = nil
    }
}

class OverlayView: UIView {
    
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
        
        self.navigationItem.leftBarButtonItem = self.sideTabBarController?.displayModeButtonItem
        self.sideTabBarController?.prefferedDisplayMode = .allVisible
        
        let label = UILabel()
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
    
    deinit {
        print("deinited \(self)")
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
        self.splitViewController?.preferredDisplayMode = .allVisible
    }
    
}
