//
//  QBRefreshControl..swift
//  QBRefresh
//
//  Created by Bing_John on 2019/8/31.
//  Copyright © 2019 Bing_John. All rights reserved.
//

import UIKit

private func getImage(imageName:String) -> UIImage? {
    let path = Bundle.main.path(forResource: "QBRefresh.bundle", ofType: nil)
    let bundle = Bundle(path: path!)
    let file2 = bundle?.path(forResource: imageName, ofType: "png")
    return UIImage(contentsOfFile: (file2!))
}

private let Image_arrow_down = getImage(imageName: "icon_arrow_down@2x")
private let Image_arrow_up = getImage(imageName: "icon_arrow_up@2x")
private let Image_loading = getImage(imageName: "icon_loading@2x")

/// 默认动画时间
private let QBDefaultDuration: TimeInterval = 0.25

// MARK: - 扩展UIScrollView,动态添加下拉刷新控件属性,方便UIScrollView使用下拉刷新
private var QBHeaderRefreshControlKey = "QBHeaderRefreshControlKey"
private var QBFooterRefreshControlKey = "QBFooterRefreshControlKey"
private var QBIsRefreshingKey = "QBIsRefreshingKey"

enum QBRefreshDirection: Int {
    case Header
    case Footer
    case Left
    case Right
}

extension UIScrollView {
    
    var isHeaderRefreshing: Bool {
        get {
            return headerRefreshControl.isRefreshing
        }
    }
    
    var isFooterRefreshing: Bool {
        get {
            return footerRefreshControl.isRefreshing
        }
    }
    
    var isRefreshing: Bool {
        get {
            return isHeaderRefreshing || isFooterRefreshing
        }
    }
    
    //    fileprivate var isRefreshing: Bool {
    //        get {
    //            return (objc_getAssociatedObject(self, &QBIsRefreshingKey) as? Int) == 1 ? true :false
    //        }
    //        set {
    //            let res = newValue == true ? 1 : 0
    //            objc_setAssociatedObject(self, &QBIsRefreshingKey, res, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
    //        }
    //    }
    
    /// 使用运行时,动态关联对象,操作起来和字典很想
    private var headerRefreshControl: QBHeaderRefreshControl {
        get {
            // 来对象身上根据key来去东西
            // object: AnyObject!: 要取东西的对象,
            // key: key,一定要记得加&
            if let refreshControl = objc_getAssociatedObject(self, &QBHeaderRefreshControlKey) as? QBHeaderRefreshControl {
                
                return refreshControl
                
            } else {
                // 在对象身上没找到需要的东西
                let refreshControl = QBHeaderRefreshControl()
                // 添加到scrollView上面
                self.addSubview(refreshControl)
                
                // 将refreshControl关联到self,会调用setter方法
                self.headerRefreshControl = refreshControl
                
                return refreshControl
            }
        }
        
        set {
            // 将newValue添加到self身上
            // bject: AnyObject!: 要添加东西的对象,
            // key: key,一定要记得加&
            // value: AnyObject!: 要添加的东西
            // policy: objc_AssociationPolicy: 策略
            objc_setAssociatedObject(self, &QBHeaderRefreshControlKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var footerRefreshControl: QBFooterRefreshControl {
        get {
            if let refreshControl = objc_getAssociatedObject(self, &QBFooterRefreshControlKey) as? QBFooterRefreshControl {
                
                return refreshControl
                
            } else {
                let refreshControl = QBFooterRefreshControl()
                self.addSubview(refreshControl)
                self.footerRefreshControl = refreshControl
                return refreshControl
            }
        }
        
        set {
            objc_setAssociatedObject(self, &QBFooterRefreshControlKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    // MARK: - 添加3个对外公开的方法,不让外部直接访问下拉刷新控件属性
    /// 添加开始刷新的闭包
    func addRefresh(direction: QBRefreshDirection, handler: @escaping () -> ()) {
        if direction == .Header {
            headerRefreshControl.refreshHandler = handler
        } else if direction == .Footer {
            footerRefreshControl.refreshHandler = handler
        }
    }
    
    /// 开始刷新
    func beginHeaderRefreshing() {
        headerRefreshControl.startRefreshing()
    }
    
    func beginFooterRefreshing() {
        footerRefreshControl.startRefreshing()
    }
    
    /// 结束刷新
    func endHeaderRefreshing() {
        headerRefreshControl.endRefreshing()
    }
    
    func endFooterRefreshing() {
        footerRefreshControl.endRefreshing()
    }
}

private let QBHeaderRefreshControlHeight: CGFloat = 60
private let QBFooterRefreshControlHeight: CGFloat = 60

/// 刷新控件的3种状态
private enum QBRefreshState: Int {
    case Idle         // 箭头朝下, 下拉刷新
    case Pulling      // 箭头朝上, 释放刷新
    case Refreshing   // 正在刷新
}

/// 刷新控件的3种状态
private enum QBRefreshHeader: String {
    case IdleText       = "下拉刷新"      // 箭头朝下, 下拉刷新
    case PullingText    = "释放刷新"      // 箭头朝上, 释放刷新
    case RefreshingText = "正在刷新..."   // 正在刷新
}

private enum QBRefreshFooter: String {
    case IdleText       = "上拉加载"      // 箭头朝下, 下拉刷新
    case PullingText    = "释放加载更多"  // 箭头朝上, 释放刷新
    case RefreshingText = "正在加载..."   // 正在刷新
}


private var headerContext = 1
private var footerContext = 2

class QBHeaderRefreshControl: UIView {
    
    // MARK: - 属性
    /// 刷新控件开始刷新的回调
    var refreshHandler: (() -> ())?
    
    /// 父类,定义属性的时候属性类型后面!
    /// UIScrollView!: 表示可选类型,隐式拆包,在使用的时候可以不用强制拆包,需要保证在使用的时候一定有值.如果值为nil,也是会挂掉
    /// 和?有区别.UIScrollView?,后面使用需要强制拆包
    /// UIScrollView!: 后面使用不需要强制拆包.如果值为nil,也是会挂掉
    private weak var scrollView: UIScrollView!
    
    var isRefreshing:Bool {
        get {
            return currentState == .Refreshing
        }
    }
    
    /// 记录上一次的状态
    private var oldState: QBRefreshState = .Idle
    
    /// 刷新控件的当前刷新状态,默认是 Normal:箭头朝下, 下拉刷新
    private var currentState: QBRefreshState = .Idle {
        didSet {
            // 状态改变后来改变UI
            switch currentState {
            case .Idle:
                // 箭头转下来,文字变为: 下拉刷新
                // 移除风火轮的旋转动画
                fhlView.layer.removeAllAnimations()
                arrowView.isHidden = false
                fhlView.isHidden = true
                messageLabel.text = QBRefreshHeader.IdleText.rawValue
                
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.arrowView.transform = CGAffineTransform.identity
                })
                
                // 只有上次是刷新状态,再切换到Normal状态的时候,才让tableView往上走刷新控件的高度,把刷新控件隐藏掉
                if oldState == .Refreshing {
                    UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                        // self.scrollView.contentInset.top -= QBHeaderRefreshControlHeight
                        self.scrollView.contentInset.top = 0
                    })
                }
            case .Pulling:
                // 箭头旋转,文字变为: 释放刷新
                messageLabel.text = QBRefreshHeader.PullingText.rawValue
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                })
                
            case .Refreshing:
                // 箭头隐藏,文字变为: 正在刷新
                arrowView.isHidden = true
                fhlView.isHidden = false
                messageLabel.text = QBRefreshHeader.RefreshingText.rawValue
                
                if (fhlView.layer.animation(forKey: "rotation") != nil) {
                    return
                }
                
                let rotation = CABasicAnimation(keyPath: "transform.rotation")
                rotation.toValue = Double.pi * 2
                rotation.duration = 0.5
                rotation.repeatCount = MAXFLOAT
                
                // forKey:如果传nil,动画叠加, forKey:不等于nil,重新动画
                fhlView.layer.add(rotation, forKey: "rotation")
                
                // 修改scrollView.contentInset.top的值,让tableView不要滚动到原来的位置,需要在往下移动刷新控件的高度,就能显示刷新控件
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.scrollView.contentInset.top = QBHeaderRefreshControlHeight
                }, completion: { (_) -> Void in
                    // 刷新控件动画到导航栏下方的时候调用
                    self.refreshHandler?()
                })
            }
            
            // 需要在didSet最下面来赋值之前的状态
            oldState = currentState
        }
    }
    
    // MARK: - 公开方法
    /// 开始刷新
    func startRefreshing() {
        currentState = .Refreshing
    }
    
    /// 结束刷新,别人加载到数据后来调用
    func endRefreshing() {
        currentState = .Idle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 移除KVO
    deinit {
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    /// 只要代码创建控件都会走这里,如果别人没有传frame,frame就是CGRectZero
    // 不管别人传入什么样的frame我都设置为我们自己的frame
    override init(frame: CGRect) {
        let newFrame = CGRect(x: 0, y: -QBHeaderRefreshControlHeight, width: UIScreen.main.bounds.size.width, height: QBHeaderRefreshControlHeight)
        super.init(frame: newFrame)
        prepareUI()
    }
    
    private func prepareUI() {
        backgroundColor = UIColor.clear
        
        // 添加子控件
        addSubview(arrowView)
        addSubview(fhlView)
        addSubview(messageLabel)
        
        // 隐藏风火轮
        fhlView.isHidden = true
        
        // 添加约束,如果想给比人用,最好不要依赖太多,尽量使用系统的API
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        fhlView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // messageLabel
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        
        // 箭头
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: messageLabel, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: -30))
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: messageLabel, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        
        // 风火轮
        addConstraint(NSLayoutConstraint(item: fhlView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: arrowView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: fhlView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: arrowView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
    }
    
    /// view即将被添加到父控件上面,当调用addSubView后会触发
    /// newSuperview: 父类
    override func willMove(toSuperview newSuperview: UIView?) {
        // 记得调用super
        super.willMove(toSuperview: newSuperview)
        
        // KVO,监听父类对象属性的改变tableView.contentOffest
        if let scrollView = newSuperview as? UIScrollView {
            self.scrollView = scrollView
            
            // scrollView.监听的对象
            // observer: NSObject: 谁来监听
            // forKeyPath: 监听的属性
            // options: New, Old
            // context: 上下文
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: &headerContext)
        }
    }
    
    /*
     keyPath: Optional("contentOffset"), change: Optional(["kind": 1])
     keyPath: Optional("contentOffset"), change: Optional(["new": NSPoint: {0, -64}, "kind": 1])
     keyPath: Optional("contentOffset"), change: Optional(["old": NSPoint: {0, -64}, "new": NSPoint: {0, -64}, "kind": 1])
     PulldownRefreshControl.swift[67行], observeValueForKeyPath(_:ofObject:change:context:): scrollView.contentOffset: (0.0, -64.0)
     */
    
    /*
     Idle <-> Pulling. 判断:contetnOffest.y = -64 - 60 = -124,还需要判断当前状态 -64. scrollView.ContentInset.Top
     1.Idle: contetnOffest.y > -124,  -120
     2.Pulling: contetnOffest.y < -124, 130
     */
    /// KVO.当监听对象的属性发生改变的时候回调用
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        // print("keyPath: \(keyPath), change: \(change)")
        if self.scrollView.isRefreshing {
            return
        }
        
        var adjustedContentInset = UIEdgeInsets.zero
        
        if #available(iOS 11, *) {
            adjustedContentInset = scrollView.adjustedContentInset
        } else {
            adjustedContentInset = scrollView.contentInset
        }
        
        let offsetY = scrollView.contentOffset.y + adjustedContentInset.top
        
        if offsetY > 0 {
            return
        }
        
        let normal2pullingOffsetY = -QBHeaderRefreshControlHeight;
        
        //        print("下拉==contentOffset: \(offsetY)", normal2pullingOffsetY)
        
        if scrollView.isDragging {
            // scrollView正在处于手指推动状态
            // 手指拖动tableView, Normal <-> PullToRefresh之间的状态切换
            if currentState == .Pulling && offsetY > normal2pullingOffsetY {   // -64. -scrollView.contentInset.top - PulldownRefreshControlHeight
                print("切换到Idle")
                currentState = .Idle
            } else if currentState == .Idle && offsetY < normal2pullingOffsetY {
                print("切换到Pulling")
                currentState = .Pulling
            }
        } else if currentState == .Pulling {
            // 手指松开
            // 当松手的时候,如果是PullToRefresh状态就切换到Refreshing,正在刷新,手指推动是没有反应的
            print("切换到Refreshing")
            currentState = .Refreshing
        }
    }
    
    // MARK: - 懒加载
    /// 箭头
    private lazy var arrowView: UIImageView = UIImageView(image: Image_arrow_down)
    /// 风火轮
    private lazy var fhlView: UIImageView = UIImageView(image: Image_loading)
    /// 提示文本
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = QBRefreshHeader.IdleText.rawValue
        return label
    }()
}

class QBFooterRefreshControl: UIView {
    
    // MARK: - 属性
    var refreshHandler: (() -> ())?
    
    private weak var scrollView: UIScrollView!
    
    var isRefreshing:Bool {
        get {
            return currentState == .Refreshing
        }
    }
    /// 记录上一次的状态
    private var oldState: QBRefreshState = .Idle
    
    /// 刷新控件的当前刷新状态,默认是 Idle:箭头朝下, 下拉刷新
    private var currentState: QBRefreshState = .Idle {
        didSet {
            // 状态改变后来改变UI
            switch currentState {
            case .Idle:
                fhlView.layer.removeAllAnimations()
                arrowView.isHidden = false
                fhlView.isHidden = true
                messageLabel.text = QBRefreshFooter.IdleText.rawValue
                
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.arrowView.transform = CGAffineTransform.identity
                })
                
                if oldState == .Refreshing {
                    UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                        self.scrollView.contentInset.bottom = 0
                    })
                }
            case .Pulling:
                messageLabel.text = QBRefreshFooter.PullingText.rawValue
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.arrowView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi))
                })
                
            case .Refreshing:
                arrowView.isHidden = true
                fhlView.isHidden = false
                
                messageLabel.text = QBRefreshFooter.RefreshingText.rawValue
                
                if (fhlView.layer.animation(forKey: "rotation") != nil) {
                    return
                }
                
                let rotation = CABasicAnimation(keyPath: "transform.rotation")
                rotation.toValue = Double.pi * 2
                rotation.duration = 0.5
                rotation.repeatCount = MAXFLOAT
                
                fhlView.layer.add(rotation, forKey: "rotation")
                
                // 修改scrollView.contentInset.top的值,让tableView不要滚动到原来的位置,需要在往下移动刷新控件的高度,就能显示刷新控件
                UIView.animate(withDuration: QBDefaultDuration, animations: { () -> Void in
                    self.scrollView.contentInset.bottom = QBFooterRefreshControlHeight
                }, completion: { (_) -> Void in
                    self.refreshHandler?()
                })
            }
            
            // 需要在didSet最下面来赋值之前的状态
            oldState = currentState
        }
    }
    
    // MARK: - 公开方法
    /// 开始刷新
    func startRefreshing() {
        currentState = .Refreshing
    }
    
    /// 结束刷新,别人加载到数据后来调用
    func endRefreshing() {
        currentState = .Idle
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // 移除KVO
    deinit {
        scrollView.removeObserver(self, forKeyPath: "contentOffset")
    }
    
    /// 只要代码创建控件都会走这里,如果别人没有传frame,frame就是CGRectZero
    // 不管别人传入什么样的frame我都设置为我们自己的frame
    override init(frame: CGRect) {
        super.init(frame: frame)
        prepareUI()
    }
    
    private func prepareUI() {
        backgroundColor = UIColor.clear
        
        // 添加子控件
        addSubview(arrowView)
        addSubview(fhlView)
        addSubview(messageLabel)
        
        // 隐藏风火轮
        fhlView.isHidden = true
        
        // 添加约束,如果想给比人用,最好不要依赖太多,尽量使用系统的API
        arrowView.translatesAutoresizingMaskIntoConstraints = false
        fhlView.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // messageLabel
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: messageLabel, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        
        // 箭头
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: messageLabel, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1, constant: -30))
        addConstraint(NSLayoutConstraint(item: arrowView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: messageLabel, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
        
        // 风火轮
        addConstraint(NSLayoutConstraint(item: fhlView, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: arrowView, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: fhlView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: arrowView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0))
    }
    
    /// view即将被添加到父控件上面,当调用addSubView后会触发
    /// newSuperview: 父类
    override func willMove(toSuperview newSuperview: UIView?) {
        // 记得调用super
        super.willMove(toSuperview: newSuperview)
        
        // KVO,监听父类对象属性的改变tableView.contentOffest
        if let scrollView = newSuperview as? UIScrollView {
            self.scrollView = scrollView
            
            scrollView.addObserver(self, forKeyPath: "contentOffset", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: &footerContext)
        }
    }
    
    /// KVO.当监听对象的属性发生改变的时候回调用
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if self.scrollView.isRefreshing {
            return
        }
        
        self.frame = CGRect(x: 0, y: scrollView.contentSize.height, width: scrollView.bounds.width, height: QBFooterRefreshControlHeight)
        
        var adjustedContentInset = UIEdgeInsets.zero
        
        if #available(iOS 11, *) {
            adjustedContentInset = scrollView.adjustedContentInset
        } else {
            adjustedContentInset = scrollView.contentInset
        }
        
        let offsetY = scrollView.contentOffset.y + adjustedContentInset.top
        
        if offsetY < 0 {
            return
        }
        
        var happenOffsetY: CGFloat = 0
        
        let contentHeight = scrollView.contentSize.height + adjustedContentInset.top + adjustedContentInset.bottom
        let scrollViewHeight = scrollView.bounds.height
        
        let pages:Int = Int(contentHeight / scrollViewHeight)
        var b = contentHeight.truncatingRemainder(dividingBy: scrollViewHeight)
        
        if pages == 0 {
            b = 0
        } else if pages >= 1 {
            happenOffsetY += CGFloat(pages - 1) * scrollViewHeight + b
        }
        
        let normal2pullingOffsetY = happenOffsetY + QBFooterRefreshControlHeight;
        
        //        print("上拉==contentOffset: \(offsetY)", normal2pullingOffsetY, b)
        
        if scrollView.isDragging {
            if currentState == .Pulling && offsetY < normal2pullingOffsetY {
                print("切换到Idle")
                currentState = .Idle
            } else if currentState == .Idle && offsetY > normal2pullingOffsetY {
                print("切换到Pulling")
                currentState = .Pulling
            }
        } else if currentState == .Pulling {
            print("切换到Refreshing")
            currentState = .Refreshing
        }
    }
    
    // MARK: - 懒加载
    /// 箭头
    private lazy var arrowView: UIImageView = UIImageView(image: Image_arrow_up)
    /// 风火轮
    private lazy var fhlView: UIImageView = UIImageView(image: Image_loading)
    /// 提示文本
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = QBRefreshFooter.IdleText.rawValue
        return label
    }()
}
