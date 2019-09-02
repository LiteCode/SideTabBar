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
// 2. Make preferredDisplayMode [ ]
// 3. Make handle that primary modal dismissed [X]
// 4. Make swipable tab bar for iPhone devices [X]
// 5. Unselect tab if primary modal controller was dismissed [X]

public protocol TabBarViewControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: UIViewController, shouldSelect viewController: UIViewController) -> Bool
    func tabBarController(_ tabBarController: UIViewController, willPresent primaryViewController: UIViewController, presentationStyle: TabBarViewController.PrimaryPresentationStyle)
    func tabBarController(_ tabBarController: UIViewController, didDismiss primaryViewController: UIViewController)
}

public extension TabBarViewControllerDelegate {
    func tabBarController(_ tabBarController: UIViewController, shouldSelect viewController: UIViewController) -> Bool { return true }
    func tabBarController(_ tabBarController: UIViewController, willPresent primaryViewController: UIViewController, presentationStyle: TabBarViewController.PrimaryPresentationStyle) { }
    func tabBarController(_ tabBarController: UIViewController, didDismiss primaryViewController: UIViewController) { }
}

open class TabBarViewController: UIViewController {
    
    public enum PrimaryPresentationStyle {
        case modal
        case primary
    }
    
    public enum DisplayMode {
        case primaryHidden
        case primaryOverlay
        case allVisible
    }
    
    public var viewControllers: [UIViewController] {
        return topViewControllers + bottomViewControllers
    }
    
    open private(set) var displayMode: DisplayMode = .primaryOverlay
    
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
    
    private var isDetailPresented: Bool {
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
            self?.setVisibleDetailViewController(for: item)
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
            self.tabBar.canDeselect = true
            
            switch self.prefferedDisplayMode {
            case .allVisible:
                if selectedViewController == nil {
                    self.tabBar.selectedItem = viewControllers[self.previousSelectedIndex].tabBarItem
                }
                self.tabBar.canDeselect = false
                self.detailRightConstraint.isActive = true
            case .primaryHidden:
                self.detailRightConstraint.isActive = false
                self.detailWidthConstraint?.constant = (self.selectedViewController == nil) ? Constants.detailHiddenWidth : self.primaryWidth
            case .primaryOverlay:
                self.detailRightConstraint.isActive = false
                self.detailWidthConstraint?.constant = (self.selectedViewController == nil) ? Constants.detailHiddenWidth : self.primaryWidth
            }
        }
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.view.layoutIfNeeded()
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
    
    private func setVisibleDetailViewController(for tabBarItem: UITabBarItem?) {
        if self.isIPhoneHorizontalSizeClass {
            guard let item = tabBarItem else { return }
            guard let index = self.viewControllers.firstIndex(where: { $0.tabBarItem === item }) else { return }
            self.previousSelectedIndex = index
            let viewControllerToShow = self.viewControllers[index]
            self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .modal)
            viewControllerToShow.presentationController?.delegate = self
            self.present(viewControllerToShow, animated: true)
            self.setTabBarVisible(false, animated: true)
            self.selectedViewController = viewControllerToShow
            self.displayMode = .primaryHidden
        } else {
            let animator = UIViewPropertyAnimator(duration: Constants.animationDuration, timingParameters: UICubicTimingParameters(animationCurve: .easeInOut))
            
            if let item = tabBarItem {
                
                guard let index = self.viewControllers.firstIndex(where: { $0.tabBarItem === item }) else { return }
                self.previousSelectedIndex = index
                let viewControllerToShow = self.viewControllers[index]
                
                if self.prefferedDisplayMode == .primaryOverlay || self.prefferedDisplayMode == .primaryHidden {
                    animator.addAnimations {
                        self.overlayView.alpha = 1
                    }
                }
                self.selectedViewController?.removeFromParentViewController()
                self.delegate?.tabBarController(self, willPresent: viewControllerToShow, presentationStyle: .primary)
                self.addChildViewController(viewControllerToShow, viewContainer: self.detailContainerView.contentView)
                self.selectedViewController = viewControllerToShow
                
                self.view.layoutIfNeeded()
                self.detailWidthConstraint?.constant = self.primaryWidth
                
            } else {
                self.view.layoutIfNeeded()
                self.detailWidthConstraint?.constant = self.prefferedDisplayMode == .primaryHidden || self.prefferedDisplayMode == .primaryOverlay ? Constants.detailHiddenWidth : self.primaryWidth
                
                animator.addAnimations {
                    self.overlayView.alpha = 0
                }
                
                if self.prefferedDisplayMode == .primaryHidden || self.prefferedDisplayMode == .primaryOverlay {
                    animator.addCompletion { state in
                        if state == .end {
                            self.displayMode = .primaryHidden
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
    }
    
    @objc private func onOverlayPressed(_ gesture: UITapGestureRecognizer) {
        self.tabBar.selectedItem = nil
    }
}

extension TabBarViewController: UIAdaptivePresentationControllerDelegate {
    
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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .fastForward, target: self, action: #selector(onDisplayModePressed))
        
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
    
    private var isAllVisible: Bool {
        return self.sideTabBarController?.prefferedDisplayMode == .allVisible
    }
    
    @objc func onDisplayModePressed() {
        let isAllVisible = self.isAllVisible
        self.sideTabBarController?.prefferedDisplayMode = isAllVisible ? .primaryHidden : .allVisible
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
        self.splitViewController?.primaryBackgroundStyle = .sidebar
        self.splitViewController?.preferredDisplayMode = .primaryOverlay
    }
    
}
