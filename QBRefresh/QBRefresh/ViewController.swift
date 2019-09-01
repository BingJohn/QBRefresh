//
//  ViewController.swift
//  QBRefresh
//
//  Created by Bing_John on 2019/9/1.
//  Copyright © 2019 Bing_John. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.overrideUserInterfaceStyle = .light

        
//        if #available(iOS 11.0, *) {
//            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
//        } else {
//            self.automaticallyAdjustsScrollViewInsets = false;
//        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
      
        tableView.addRefresh(direction: .Header) {
            print("==下拉加载数据==")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.tableView.endHeaderRefreshing()
            }
        }
        
        tableView.addRefresh(direction: .Footer) {
            print("==上拉加载数据==")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.tableView.endFooterRefreshing()
            }
        }
    }
    
    
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.backgroundColor = UIColor(red: CGFloat(arc4random_uniform(256)) / 255.0, green: CGFloat(arc4random_uniform(256)) / 255.0, blue: CGFloat(arc4random_uniform(256)) / 255.0, alpha: 1.0)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("scrollView.contentOffset: \(self.tableView.contentOffset.y)", self.tableView.contentInset.top)
    }
}


