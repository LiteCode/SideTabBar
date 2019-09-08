//
//  TableTestViewController.swift
//  SideTabBar_Example
//
//  Created by Vladislav Prusakov on 08.09.2019.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

class TableTestViewController: UITableViewController {
    
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
        viewController.view.backgroundColor = .white
        self.sideTabBarController?.setContentViewController(UINavigationController(rootViewController: viewController))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
