//
//  SideTabBarController.swift
//  SideTabBarController
//
//  Created by Vladislav Prusakov on 20.08.2019.
//  Copyright © 2019 Vladislav Prusakov. All rights reserved.
//

import UIKit

/// A set of methods you implement to customize the behavior of a tab bar.
public protocol SideTabBarControllerDelegate: AnyObject {
    
    /// Asks the delegate whether the specified view controller should be made active.
    func tabBarController(_ tabBarController: SideTabBarController, shouldSelect viewController: UIViewController) -> Bool
    
    /// Tells the delegate that primary view controller will change presentation style.
    func tabBarController(_ tabBarController: SideTabBarController, willPresent primaryViewController: UIViewController, presentationStyle: SideTabBarController.PrimaryPresentationStyle)
    
    /// Tells the delegate that primary view controller did dismiss.
    func tabBarController(_ tabBarController: SideTabBarController, didDismiss primaryViewController: UIViewController)
    
    /// Called to allow the delegate to provide the image for display bar button item.
    func tabBarController(_ tabBarController: SideTabBarController, didUpdateBarButtonItemForDisplayMode: SideTabBarController.DisplayMode) -> UIImage?
    
    /// Tells the delegate that the tab bar controlled will change display mode.
    func tabBarController(_ tabBarController: SideTabBarController, willChangeTo displayMode: SideTabBarController.DisplayMode)
}

public extension SideTabBarControllerDelegate {
    func tabBarController(_ tabBarController: SideTabBarController, shouldSelect viewController: UIViewController) -> Bool { return true }
    func tabBarController(_ tabBarController: SideTabBarController, willPresent primaryViewController: UIViewController, presentationStyle: SideTabBarController.PrimaryPresentationStyle) { }
    func tabBarController(_ tabBarController: SideTabBarController, didDismiss primaryViewController: UIViewController) { }
    func tabBarController(_ tabBarController: SideTabBarController, willChangeTo displayMode: SideTabBarController.DisplayMode) { }
}

/// A container view controller that manages a radio-style selection interface. Selected determines which child view controller display as side menu.
open class SideTabBarController: UIViewController {
    
    /// Constants describing the possible presentation style for primary view controller.
    public enum PrimaryPresentationStyle: Int {
        /// The primary view controller displayed as model
        case modal
        /// The primary view controller displayed as part of split view.
        case splitView
    }
    
    /// Constants describing the possible display modes for a split view controller.
    public enum DisplayMode: Int {
        /// The primary view controller is hidden.
        case primaryHidden
        /// The primary view controller is layered on top of the secondary view controller, leaving the secondary view controller partially visible.
        case primaryOverlay
        /// The primary view controller display as modal.
        case primaryModal
        /// The primary and secondary view controllers are displayed side-by-side onscreen.
        case allVisible
    }
    
    /// An array of the view controllers displayed by the tab bar interface.
    public var viewControllers: [UIViewController] {
        return topViewControllers + bottomViewControllers
    }
    
    /// The current arrangement of the split's contents.
    /// This property reflects the arrangement of the two child view controllers in a split view interface.
    open private(set) var displayMode: DisplayMode = .primaryHidden {
        willSet {
            self.delegate?.tabBarController(self, willChangeTo: newValue)
        }
        didSet {
            self.updateDisplayModeBarButtonItem()
        }
    }
    
    /// The preferred arrangement of the split interface.
    open var prefferedDisplayMode: DisplayMode = .primaryOverlay {
        didSet {
            self.updateViewState()
        }
    }
    
    /// A float value that set width for tab bar.
    /// The default value is 70.
    open var tabBarWidth: CGFloat = 70 {
        didSet {
            self.tabBarWidthConstraint?.constant = self.tabBarWidth
            self.updateViewState()
        }
    }
    
    /// A float value that set width for primary view.
    /// The default value is 375.
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
    
    /// The tab bar controller’s delegate object.
    public weak var delegate: SideTabBarControllerDelegate?
    
    /// The tab bar view associated with this controller.
    public private(set) weak var tabBar: SideTabBar!
    
    /// The view controller associated with the currently selected tab item.
    public private(set) weak var selectedViewController: UIViewController?
    
    /// The root view controller associated with the tab bar.
    public private(set) weak var contentViewController: UIViewController?
    
    /// A Boolean indicating whether the underlying content is obscured during a menu presented
    ///
    /// The default value of this property is true.
    open var obscuresBackgroundDuringPresentation: Bool = true {
        didSet {
            self.updateOverlayView()
        }
    }
    
    /// A visual effect what used by default for tab bar and primary view.
    open var backgroundVisualEffect: UIVisualEffect = UIBlurEffect(style: .systemChromeMaterial) {
        didSet {
            self.primaryContainerView?.effect = self.backgroundVisualEffect
            self.tabBar?.visualEffect = self.backgroundVisualEffect
        }
    }
    
    /// A button that changes the display mode of the split view controller.
    open private(set) lazy var displayModeButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .done, target: self, action: #selector(onDisplayModeButtonItemPressed(barButtonItem:)))
    }()
    
    // MARK: Views
    private weak var primaryContainerView: UIVisualEffectView!
    private weak var contentContainerView: UIView!
    private weak var overlayView: OverlayView!
    private weak var separatorView: UIView!
    
    // MARK: Constraints
    private var primaryWidthConstraint: NSLayoutConstraint!
    private var primaryRightConstraint: NSLayoutConstraint!
    private weak var tabBarWidthConstraint: NSLayoutConstraint?
    private var tabBarLeftConstraint: NSLayoutConstraint!
    
    // MARK: Other
    private lazy var topViewControllers: [UIViewController] = []
    private lazy var bottomViewControllers: [UIViewController] = []
    private var previousSelectedIndex: Int = 0
    
    /// A Boolean value indicating whether only one of the child view controllers is displayed.
    open var isCollapsed: Bool {
        return self.primaryWidthConstraint.constant != Constants.detailHiddenWidth
    }
    
    /// A Boolean value indicating that tab bar is displayed.
    open private(set) var isTabBarPresented: Bool = false
    
    private enum Constants {
        static let detailHiddenWidth: CGFloat = 0
        static let animationDuration: TimeInterval = 0.15
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setup()
    }
    
    /// Sets the view controllers of the tab bar controller.
    /// - Parameter viewControllers: The array of custom view controllers to display in the tab bar interface. The order of the view controllers in this array corresponds to the display order in the tab bar, with the controller at index 0 representing the top-most tab, the controller at index 1 the next tab to the below, and so on.
    /// - Parameter positioning: Set position for items on tab bar.
    /// - Parameter animated: If true, the tab bar items for the view controllers are animated into position. If false, changes to the tab bar items are reflected immediately.
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
    
    /// Set the root view controller of the tab view controller.
    /// - Parameter contentViewController: The view controller to display like root.
    open func setContentViewController(_ contentViewController: UIViewController) {
        self.contentViewController?.removeFromParentViewController()
        self.addChildViewController(contentViewController, viewContainer: self.contentContainerView)
        self.contentViewController = contentViewController
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
        
        let primaryContainerView = UIVisualEffectView()
        primaryContainerView.effect = self.backgroundVisualEffect
        primaryContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(primaryContainerView)
        self.primaryContainerView = primaryContainerView
        
        let overlayView = OverlayView(target: self, action: #selector(onOverlayPressed(_:)))
        overlayView.backgroundColor = UIColor.barHairlineColor
        overlayView.translatesAutoresizingMaskIntoConstraints = false
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
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(onTabBarPanGesture))
        tabBar.addGestureRecognizer(panGesture)
        
        view.addSubview(tabBar)
        self.tabBar = tabBar
        
        let primaryWidthConstraint = primaryContainerView.widthAnchor.constraint(equalToConstant: Constants.detailHiddenWidth)
        primaryWidthConstraint.priority = UILayoutPriority(rawValue: 999)
        let tabBarWidthConstraint = tabBar.widthAnchor.constraint(equalToConstant: self.tabBarWidth)
        let primaryRightConstraint = primaryContainerView.rightAnchor.constraint(equalTo: contentContainerView.leftAnchor)
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
            
            primaryWidthConstraint,
            primaryContainerView.leftAnchor.constraint(equalTo: tabBar.rightAnchor),
            primaryContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            primaryContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            separatorView.leftAnchor.constraint(equalTo: primaryContainerView.rightAnchor),
            separatorView.topAnchor.constraint(equalTo: view.topAnchor),
            separatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            separatorView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            
            overlayView.leftAnchor.constraint(equalTo: separatorView.rightAnchor),
            overlayView.rightAnchor.constraint(equalTo: view.rightAnchor),
            overlayView.topAnchor.constraint(equalTo: view.topAnchor),
            overlayView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        self.tabBarLeftConstraint = tabBarLeftConstraint
        self.tabBarWidthConstraint = tabBarWidthConstraint
        self.primaryWidthConstraint = primaryWidthConstraint
        self.primaryRightConstraint = primaryRightConstraint
        
        self.updateViewState()
    }
    
    private func updateOverlayView() {
        self.overlayView.backgroundColor = obscuresBackgroundDuringPresentation ? UIColor.barHairlineColor : .clear
    }
    
    private func updateViewState() {
        if self.isIPhoneHorizontalSizeClass {
            self.additionalSafeAreaInsets.left = 0
            self.primaryRightConstraint.isActive = false
            self.setTabBarVisible(false, animated: false)
            self.tabBar.canDeselect = true
            self.primaryWidthConstraint.constant = Constants.detailHiddenWidth
        } else {
            self.setTabBarVisible(true, animated: false)
            self.additionalSafeAreaInsets.left = self.tabBarWidth
            
            let displayMode = self.posibleDisplayMode(from: self.prefferedDisplayMode)
            
            switch displayMode {
            case .allVisible:
                self.tabBar.canDeselect = false
                self.primaryRightConstraint.isActive = true
            case .primaryHidden, .primaryOverlay, .primaryModal:
                self.tabBar.canDeselect = true
                self.primaryRightConstraint.isActive = false
            }
            
            self.primaryWidthConstraint.constant = (self.selectedViewController == nil) ? Constants.detailHiddenWidth : self.primaryWidth
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
            self.overlayView.dismiss()
            viewControllerToShow.removeFromParentViewController()
            self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .modal)
            viewControllerToShow.presentationController?.delegate = self
            self.present(viewControllerToShow, animated: false)
        } else {
            self.overlayView.display()
            self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .splitView)
            viewControllerToShow.dismiss(animated: false, completion: {
                self.addChildViewController(viewControllerToShow, viewContainer: self.primaryContainerView.contentView)
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
    
    @objc private func onTabBarPanGesture(_ gesture: UIPanGestureRecognizer) {
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
            self.primaryWidthConstraint.constant = Constants.detailHiddenWidth
            
            let animator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
            
            animator.addAnimations {
                self.overlayView.dismiss()
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
                self.primaryRightConstraint.isActive = true
                self.selectedViewController?.removeFromParentViewController()
                self.addChildViewController(viewController, viewContainer: self.primaryContainerView.contentView)
                self.view.layoutIfNeeded()
                
                animator.addAnimations {
                    self.overlayView.dismiss()
                }
                
                self.delegate?.tabBarController(self, willPresent: viewController, presentationStyle: .splitView)
                self.displayMode = .allVisible
                self.primaryWidthConstraint.constant = self.primaryWidth
            case .primaryModal, .primaryOverlay, .primaryHidden:
                self.tabBar.canDeselect = true
                self.selectedViewController?.removeFromParentViewController()
                self.addChildViewController(viewController, viewContainer: self.primaryContainerView.contentView)
                self.view.layoutIfNeeded()
                
                self.primaryWidthConstraint.constant = self.primaryWidth
                
                animator.addAnimations {
                    self.overlayView.display()
                }
                
                self.displayMode = .primaryOverlay
                self.delegate?.tabBarController(self, willPresent: viewController, presentationStyle: .splitView)
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

public extension UIViewController {
    
    /// The nearest ancestor in the view controller hierarchy that is a side tab bar controller.
    var sideTabBarController: SideTabBarController? {
        if let tabBar = self.parent as? SideTabBarController {
            return tabBar
        } else if let navController = self.parent as? UINavigationController {
            return navController.sideTabBarController
        } else if let tabController = self.parent as? UITabBarController {
            return tabController.sideTabBarController
        }
        
        return nil
    }
}


// MARK: - UIAdaptivePresentationControllerDelegate

extension SideTabBarController: UIAdaptivePresentationControllerDelegate {
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.delegate?.tabBarController(self, didDismiss: presentationController.presentedViewController)
        self.tabBar.selectedItem = nil
        self.selectedViewController = nil
    }
}

class OverlayView: UIView {
    
    private weak var tapGesture: UITapGestureRecognizer?
    
    init(target: AnyObject, action: Selector) {
        super.init(frame: .zero)
        self.alpha = 0
        let gesture = UITapGestureRecognizer(target: target, action: action)
        self.addGestureRecognizer(gesture)
        self.tapGesture = gesture
    }
    
    var isDisplayed: Bool {
        return alpha != 0
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.isDisplayed
    }
    
    func display() {
        self.alpha = 1
    }
    
    func dismiss() {
        self.alpha = 0
    }
}

//// MARK: - Test Controllers
//
//private class TestViewController: UIViewController {
//    
//    private weak var label: UILabel!
//    
//    init(tabBarItem: UITabBarItem) {
//        super.init(nibName: nil, bundle: nil)
//        self.tabBarItem = tabBarItem
//    }
//    
//    init(name: String) {
//        super.init(nibName: nil, bundle: nil)
//        self.tabBarItem = UITabBarItem(title: name, image: nil, selectedImage: nil)
//    }
//    
//    deinit {
//        print("deinited controller with title:", tabBarItem.title ?? "<WITHOUT TITLE>")
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        self.navigationItem.leftBarButtonItem = self.sideTabBarController?.displayModeButtonItem
//        self.sideTabBarController?.prefferedDisplayMode = .primaryOverlay
//        
//        let label = UILabel()
//        label.text = self.tabBarItem.title
//        label.translatesAutoresizingMaskIntoConstraints = false
//        label.textAlignment = .center
//        self.view.addSubview(label)
//        self.label = label
//        
//        NSLayoutConstraint.activate([
//            label.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
//            label.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
//            label.leftAnchor.constraint(equalTo: self.view.leftAnchor)
//        ])
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//private class TableTestViewController: UITableViewController {
//    
//    init(tabBarItem: UITabBarItem) {
//        super.init(nibName: nil, bundle: nil)
//        self.tabBarItem = tabBarItem
//    }
//    
//    deinit {
//        print("deinited \(self)")
//    }
//    
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return 20
//    }
//    
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        return tableView.dequeueReusableCell(withIdentifier: "identifier") ?? UITableViewCell(style: .default, reuseIdentifier: "identifier")
//    }
//    
//    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        cell.backgroundColor = .clear
//        cell.textLabel?.text = "Some index \(indexPath.row)"
//    }
//    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let viewController = TestViewController(name: "Some index \(indexPath.row)")
//        self.sideTabBarController?.setContentViewController(UINavigationController(rootViewController: viewController), sender: nil)
//    }
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.tableView.backgroundColor = .clear
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
