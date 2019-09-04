//
//  ViewController.swift
//  QBRefresh
//
//  Created by Bing_John on 2019/9/1.
//  Copyright © 2019 Bing_John. All rights reserved.
//

import UIKit

private func KNavHeight(target: UIViewController) -> CGFloat {
    var navHeight: CGFloat = 0
    if #available(iOS 11, *) {
        navHeight = UIApplication.shared.keyWindow!.safeAreaInsets.top
    } else {
        navHeight = UIApplication.shared.statusBarFrame.height
    }
    return navHeight +  (target.navigationController?.navigationBar.frame.height)!
}

/// 默认动画时间
private let QBDefaultDuration: TimeInterval = 0.25

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    private var dataSource: [Int]? {
        didSet {
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.overrideUserInterfaceStyle = .light

        
//        if #available(iOS 11.0, *) {
//            UIScrollView.appearance().contentInsetAdjustmentBehavior = .never
//        } else {
//            self.automaticallyAdjustsScrollViewInsets = false;
//        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        dataSource = [1, 2, 3, 4, 5, 6, 7, 8, 9]
        
      
        tableView.addRefresh(direction: .Header) {
            print("==下拉加载数据==")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.showTipLabel(count: 3)
                self.dataSource = [1, 2, 3, 4, 5, 6, 7, 8, 9]
            }
        }
        
        tableView.addRefresh(direction: .Footer) {
            print("==上拉加载数据==")
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                self.tableView.endFooterRefreshing()
                self.dataSource = self.dataSource! + [1, 3, 4, 6, 7, 8]
            }
        }
    }
    
    
   /// 显示下拉刷新的条数
    private func showTipLabel(count: Int) {
        tipLabel.text = count == 0 ? "没有新数据" : "更新了\(count)条数据"
        
        // 动画叠加导致label还会往下走,UIView动画的底层也是核心动画
        let animationKeys = tipLabel.layer.animationKeys()
        
        if animationKeys != nil {
            print("有动画在运行,移除: \(animationKeys!)")
            // 移除之前的动画
            tipLabel.layer.removeAllAnimations()
        }
        
        // 动画
        
        UIView.animate(withDuration: QBDefaultDuration * 4, animations: {
            self.tipLabel.frame.origin.y = KNavHeight(target: self)
        }) { (_) in
            
            UIView.animate(withDuration: QBDefaultDuration * 4, delay: QBDefaultDuration * 4, options: UIView.AnimationOptions(rawValue: 0), animations: {
                self.tipLabel.frame.origin.y = -KNavHeight(target: self)
                self.tableView.endHeaderRefreshing()
            }) { (_) in
               
            }
        }
    }
    
    // MARK: - 懒加载
    /// 下拉刷新提示label
    private lazy var tipLabel: UILabel = {
        let tipLabel = UILabel()
        
        tipLabel.backgroundColor = UIColor.orange
        tipLabel.textColor = UIColor.white
        tipLabel.font = UIFont.systemFont(ofSize: 16)
        tipLabel.textAlignment = NSTextAlignment.center
        
        tipLabel.frame = CGRect(x: 0, y: -KNavHeight(target: self), width: UIScreen.main.bounds.width, height: 44)
        
        // 往导航栏上面添加
        self.view.insertSubview(tipLabel, aboveSubview: self.tableView)
//      self.navigationController?.navigationBar.insertSubview(tipLabel, at: 0)
      
        return tipLabel
    }()
    
}


extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataSource?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "\(indexPath.row)"
        cell.backgroundColor = UIColor(red: CGFloat(arc4random_uniform(256)) / 255.0, green: CGFloat(arc4random_uniform(256)) / 255.0, blue: CGFloat(arc4random_uniform(256)) / 255.0, alpha: 1.0)
        return cell
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        print("scrollView.contentOffset: \(self.tableView.contentOffset.y)", self.tableView.contentInset.top)
    }
}


