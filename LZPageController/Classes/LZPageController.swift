//
//  LZPageController.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/10.
//  Copyright © 2019 lizhi. All rights reserved.
//

import UIKit

enum LZPageControllerPreloadPolicy: Int {
    case never = 0 // Never pre-load controller.
    case neighbour = 1// Pre-load the controller next to the current.
    case near = 2// Pre-load 2 controllers near the current.
}

extension NSNotification.Name {
    static let LZControllerDidAddToSuperViewNotification = NSNotification.Name("LZControllerDidAddToSuperViewNotification")
    static let LZControllerDidFullyDisplayedNotification = NSNotification.Name("LZControllerDidFullyDisplayedNotification")
}


let kLZUndefinedIndex: Int = -1;
let kLZControllerCountUndefined: Int = -1;

class LZPageController: UIViewController {
    
    //MARK:可设置属性
    weak var delegate: LZPageControllerDelegate?
    weak var dataSource: LZPageControllerDataSource?
    
    /**
     *  Values and keys can set properties when initialize child controlelr (it's KVC)
     *  values keys 属性可以用于初始化控制器的时候为控制器传值(利用 KVC 来设置)
        使用时请确保 key 与控制器的属性名字一致！！(例如：控制器有需要设置的属性 type，那么 keys 所放的就是字符串 @"type")
     */
    var values: [AnyObject]?
    var keys: [String]?
    

    /**
     *  各个控制器的 class, 例如:[UITableViewController class]
     *  Each controller's class, example:[UITableViewController class]
     */
    var viewControllerClasses: [UIViewController.Type]?

    /**
     *  各个控制器标题
     *  Titles of view controllers in page controller.
     */
    var titles: [String]?
    
    /**
    *  当前显示的控制器
    *  the view controller showing.
    */
    private(set) var currentViewController:  UIViewController?
    
    /**
     *  设置选中几号 item
     *  To select item at index
     */
    
    private var _selectIndex: Int = 0
    
    var selectIndex: Int {
        set {
            _selectIndex = newValue
            
            markedSelectIndex = kLZUndefinedIndex;
            
            if let menuView = self.menuView, hasInited {
                menuView.selectItemAtIndex(newValue)
            }else {
                markedSelectIndex = newValue
                var vc = self.memCache.object(forKey: NSNumber(value: newValue))
                if vc == nil {
                    vc = self.initializeViewControllerAtIndex(newValue)
                    if vc != nil {
                        self.memCache.setObject(vc!, forKey: NSNumber(value: newValue))
                    }
                }
                currentViewController = vc
            }
        }
        get {
            return _selectIndex
        }
    }
    
    /**
     *  点击的 MenuItem 是否触发滚动动画 默认为 true
     *  Whether to animate when press the MenuItem
     */
    var pageAnimatable = true
    
    /** 是否自动通过字符串计算 MenuItem 的宽度，默认为 false. */
    var automaticallyCalculatesItemWidths = false
    

    /** Whether the controller can scroll. Default is YES. */
    var scrollEnable = true {
        didSet {
            if let scrollView = self.scrollView {
                scrollView.isScrollEnabled = scrollEnable
            }
        }
    }
    
    /**
     *  选中时的标题尺寸
     *  The title size when selected (animatable)
     */
    var titleSizeSelected: CGFloat = 16
    
    /**
     *  非选中时的标题尺寸
     *  The normal title size (animatable)
     */
    var titleSizeNormal: CGFloat = 16
    
    /**
     *  标题选中时的颜色, 颜色是可动画的.
     *  The title color when selected, the color is animatable.
     */
    var titleColorSelected: UIColor = UIColor.lightGray
    
    /**
     *  标题非选择时的颜色, 颜色是可动画的.
     *  The title's normal color, the color is animatable.
     */
    var titleColorNormal: UIColor = UIColor.black
    
    /**
     *  标题的字体名字
     *  The name of title's font
     */
    var titleFontName: String?
    
    /**
     *  每个 MenuItem 的宽度
     *  The item width,when all are same,use this property
     */
    var menuItemWidth: CGFloat = 65.0
    
    /**
     *  各个 MenuItem 的宽度，可不等
     *  Each item's width, when they are not all the same, use this property, Put `CGFloat` in this array.
     */
    var itemsWidths: [CGFloat]?
    
    /**
     *  Menu view 的样式，默认为无下划线
     *  Menu view's style, now has two different styles, 'Line','default'
     */
    var menuViewStyle: LZMenuViewStyle = .styleDefault
    
    var menuViewLayoutMode: LZMenuViewLayoutMode = .scatter {
        didSet {
            if self.menuView?.superview != nil {
                self.lz_resetMenuView()
            }
        }
    }
    
    /**
     *  进度条的颜色，默认和选中颜色一致(如果 style 为 Default，则该属性无用)
     *  The progress's color,the default color is same with `titleColorSelected`.If you want to have a different color, set this property.
     */
    var progressColor: UIColor? {
        didSet {
            self.menuView?.adjustLineColor(progressColor)
        }
    }
    
    /**
     *  定制进度条在各个 item 下的宽度
     */
    var progressViewWidths: [CGFloat]? {
        didSet {
            if let menuView = self.menuView {
                menuView.progressWidths = progressViewWidths
            }
        }
    }
    
    /// 定制进度条，若每个进度条长度相同，可设置该属性
    var progressWidth: CGFloat = 0 {
        didSet {
            if progressWidth > 0 {
                var tmp = [CGFloat]()
                
                for _ in 0..<childControllersCount {
                    tmp.append(progressWidth)
                }
                
                self.progressViewWidths = tmp
            }
        }
    }
    
    /// 调皮效果，用于实现腾讯视频新效果，请设置一个较小的 progressWidth
    var progressViewIsNaughty: Bool? {
        didSet {
            if let isNaughty = progressViewIsNaughty {
                self.menuView?.progressViewIsNaughty = isNaughty
            }
        }
    }

    /**
     *  是否发送在创建控制器或者视图完全展现在用户眼前时通知观察者，默认为不开启，如需利用通知请开启
     *  Whether notify observer when finish init or fully displayed to user, the default is false.
     *  See `JWPageConst.h` for more information.
     */
    var postNotification = false

    /** 缓存的机制，默认为无限制 (如果收到内存警告, 会自动切换) */
    var cachePolicy: LZPageControllerCachePolicy = .noLimit {
        didSet {
            if (cachePolicy != .disabled) {
                self.memCache.countLimit = cachePolicy.rawValue
            }
        }
    }

    /** 预加载机制，在停止滑动的时候预加载 n 页 */
    var preloadPolicy: LZPageControllerPreloadPolicy = .never
    
    /** Whether ContentView bounces */
    var bounces: Bool = false
    
    /**
     *  是否作为 NavigationBar 的 titleView 展示，默认 false
     *  Whether to show on navigation bar, the default value is `false`
     */
    var showOnNavigationBar = false {
        didSet {
            if showOnNavigationBar != oldValue {
                if let menuView = self.menuView {
                    menuView.removeFromSuperview()
                    self.lz_addMenuView()
                    self.forceLayoutSubviews()
                    menuView.slideMenuAtProgress(CGFloat(selectIndex))
                }
            }
        }
    }
    
    /**
     *  用代码设置 contentView 的 contentOffset 之前，请设置 startDragging = YES
     *  Set startDragging = YES before set contentView.contentOffset = xxx;
     */
    var startDragging = false
    
    /** 下划线进度条的高度 */
    var progressHeight: CGFloat = LZUNDEFINED_VALUE
    
    /**
     *  Menu view items' margin / make sure it's count is equal to (controllers' count + 1),default is 0
        顶部菜单栏各个 item 的间隙，因为包括头尾两端，所以确保它的数量等于控制器数量 + 1, 默认间隙为 0
     */
    var itemsMargins: [CGFloat]?
    
    /**
     *  set itemMargin if all margins are the same, default is 0
        如果各个间隙都想同，设置该属性，默认为 0
     */
    var itemMargin: CGFloat?
    
    /** progressView 到 menuView 底部的距离 */
    var progressViewBottomSpace: CGFloat?
    
    /** progressView's cornerRadius */
    var progressViewCornerRadius: CGFloat = LZUNDEFINED_VALUE {
        didSet {
            if let menuView = self.menuView {
                menuView.progressViewCornerRadius = progressViewCornerRadius
            }
        }
    }
    
    /** 顶部导航栏 */
    weak var menuView: LZMenuView?

    /** 内部容器 */
    weak var scrollView: LZPageScrollView?
    
    /** MenuView 内部视图与左右的间距 */
    var menuViewContentMargin: CGFloat? {
        didSet {
            if let contentMargin = menuViewContentMargin {
                self.menuView?.contentMargin = contentMargin
            }
        }
    }
    
    var childControllersCount: Int {
        get {
            if controllerCount == kLZControllerCountUndefined {
                if let dataSource = self.dataSource {
                    if let number = dataSource.numbersOfChildControllersInPageController?(self) {
                        controllerCount = number
                        
                        return controllerCount
                    }
                }
                if let cnt = self.viewControllerClasses?.count {
                    controllerCount = cnt
                }
            }
            return controllerCount
        }
    }
    
    //私有属性
    var targetX: CGFloat = 0
    var contentViewFrame: CGRect = .zero, menuViewFrame: CGRect = .zero
    var hasInited = false
    var shouldNotScroll = false
    var initializedIndex = kLZUndefinedIndex
    var controllerCount = kLZControllerCountUndefined
    var markedSelectIndex = kLZUndefinedIndex

    // 用于记录子控制器view的frame，用于 scrollView 上的展示的位置
    var childViewFrames = [CGRect]()
    // 当前展示在屏幕上的控制器，方便在滚动的时候读取 (避免不必要计算)
    lazy var displayVC = [Int: UIViewController]()
    // 用于记录销毁的viewController的位置 (如果它是某一种scrollView的Controller的话)
    lazy var posRecords = [Int: CGPoint]()

    // 用于缓存加载过的控制器
    let memCache = NSCache<NSNumber, UIViewController>()

    lazy var backgroundCache = [Int: UIViewController]()

    // 收到内存警告的次数
    var memoryWarningCount: Int = 0
    
    func forceLayoutSubviews() {
        if childControllersCount <= 0 {
            return
        }
        self.lz_calculateSize()
        self.lz_adjustScrollViewFrame()
        self.lz_adjustMenuViewFrame()
        self.lz_adjustDisplayingViewControllersFrame()
    }
    
    /**
     *  构造方法，请使用该方法创建控制器. 或者实现数据源方法. /
     *  Init method，recommend to use this instead of `-init`. Or you can implement datasource by yourself.
     *
     *  @param classes 子控制器的 class，确保数量与 titles 的数量相等
     *  @param titles  各个子控制器的标题，用 NSString 描述
     *
     *  @return instancetype
     */
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        lz_setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        lz_setup()
    }
    
    convenience init(withViewControllerClasses classes: [UIViewController.Type], andTheirTitles titles: [String]) {
        self.init(nibName: nil, bundle: nil)
        self.viewControllerClasses = classes
        self.titles = titles
    }
    //MARK: -- life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.automaticallyAdjustsScrollViewInsets = false
        self.view.backgroundColor = UIColor.white
//        _controllerCount = kJWControllerCountUndefined;//因为项目可能刚开始是未登录，然后还未viewdidload就又登录了，那么这里_controllerCount就不会再初始化，造成crash，所以在viewdidload再初始化一下kJWControllerCountUndefined就可以保证没问题
        if childControllersCount == kLZControllerCountUndefined {
            return
        }
        lz_calculateSize()
        lz_addScrollView()
        lz_addMenuView()
        
        lz_initializedControllerWithIndexIfNeeded(selectIndex)
        currentViewController = displayVC[selectIndex]
        didEnterController(currentViewController, atIndex: selectIndex)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if childControllersCount <= 0 {
            return
        }
        self.forceLayoutSubviews()
        hasInited = true
        self.lz_delaySelectIndexIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        memoryWarningCount += 1
        cachePolicy = .lowMemory
        // 取消正在增长的 cache 操作
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyToHigh), object: nil)
        memCache.removeAllObjects()
        posRecords.removeAll()
        // 如果收到内存警告次数小于 3，一段时间后切换到模式 Balanced
        if memoryWarningCount < 3 {
            self.perform(#selector(lz_growCachePolicyAfterMemoryWarning), with: nil, afterDelay: 3.0, inModes: [RunLoopMode.commonModes])
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyToHigh), object: nil)
    }
    //MARK: - Delegate
    func infoWithIndex(_ index: Int) -> Dictionary<String, Any> {
        let title = self.titleAtIndex(index)
        return ["title": title, "index": index]
    }
    
    func willCachedController(_ vc: UIViewController, atIndex index: Int) {
        if childControllersCount > 0 {
            let info = self.infoWithIndex(index)
            self.delegate?.pageController?(self, willCachedViewController: vc, withInfo: info)
        }
    }
    
    func willEnterController(_ vc: UIViewController, atIndex index: Int) {
        _selectIndex = index
        if childControllersCount > 0 {
            let info = self.infoWithIndex(index)
            self.delegate?.pageController?(self, willEnterViewController: vc, withInfo: info)
        }
    }
    
    // 完全进入控制器 (即停止滑动后调用)
    func didEnterController(_ vc: UIViewController?, atIndex index: Int) {
        guard childControllersCount > 0 else {
            return
        }
        guard let vc = vc else { return  }
       //wanning selectindex replace index??
       // Post FullyDisplayedNotification
        self.lz_postFullyDisplayedNotificationWithCurrentIndex(index)
        let info = self.infoWithIndex(index)
        self.delegate?.pageController?(self, didEnterViewController: vc, withInfo: info)
        
        // 当控制器创建时，调用延迟加载的代理方法
        if initializedIndex == index {
            self.delegate?.pageController?(self, lazyLoadViewController: vc, withInfo: info)
            initializedIndex = kLZUndefinedIndex
        }
        
        if preloadPolicy == .never {
            return
        }
        
        // 根据 preloadPolicy 预加载控制器
        let length = preloadPolicy.rawValue
        
        var start: Int = 0
        var end = childControllersCount - 1
        if index > length {
            start = index - length
        }
        if childControllersCount - 1 > length + index {
            end = index + length
        }
        
        for i in start...end {
            if self.memCache.object(forKey: NSNumber(value: i)) == nil && self.displayVC[i] == nil {
                self.lz_addViewControllerAtIndex(i)
                self.lz_postAddToSuperViewNotificationWithIndex(i)
            }
        }
        _selectIndex = index
    }

    //MARK: - Data source
    func initializeViewControllerAtIndex(_ index: Int) -> UIViewController? {
        
        if let vc = self.dataSource?.pageController?(self, viewControllerAtIndex: index) {
            return vc
        }
        
        if let classType = viewControllerClasses?[index] {
            return classType.init()
        }
        return nil
    }

    //MARK: - Private Methods
    func lz_resetScrollView() {
        if let scrollView = self.scrollView {
            scrollView.removeFromSuperview()
        }
        self.lz_addScrollView()
        self.lz_addViewControllerAtIndex(self.selectIndex)
        currentViewController = displayVC[_selectIndex]
    }
    
    func lz_clearDatas() {
        controllerCount = kLZControllerCountUndefined
        hasInited = false
        let maxIndex = (self.childControllersCount - 1 > 0) ? self.childControllersCount - 1 : 0
        _selectIndex = (selectIndex < childControllersCount ? selectIndex : maxIndex)
        
        let preProgressWidth = progressWidth;
        if preProgressWidth > 0 {
            self.progressWidth = preProgressWidth
        }
        
        for vc in displayVC.values {
            vc.view.removeFromSuperview()
            vc.willMove(toParentViewController: nil)
            vc.removeFromParentViewController()
        }
        
        memoryWarningCount = 0
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyAfterMemoryWarning), object: nil)
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(lz_growCachePolicyToHigh), object: nil)
        currentViewController = nil
        posRecords.removeAll()
        backgroundCache.removeAll()
        displayVC.removeAll()
    }

    // 当子控制器init完成时发送通知
    func lz_postAddToSuperViewNotificationWithIndex(_ index: Int) {
        guard postNotification else {
            return
        }
        let info = ["index": index, "title": self.titleAtIndex(index)] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name.LZControllerDidAddToSuperViewNotification, object: self, userInfo: info)
    }
    
    // 当子控制器完全展示在user面前时发送通知
    func lz_postFullyDisplayedNotificationWithCurrentIndex(_ index: Int) {
        guard postNotification else {
            return
        }
        let info = ["index": index, "title": self.titleAtIndex(index)] as [String : Any]
        NotificationCenter.default.post(name: NSNotification.Name.LZControllerDidFullyDisplayedNotification, object: self, userInfo: info)
    }
    
    func lz_setup() {
        self.dataSource = self
        self.delegate = self
        cache_setup()
    }
    
    func lz_calculateSize() {
        
        guard let menuFrame = self.dataSource?.pageController(self, preferredFrameForMenuView: self.menuView) else { return }
        self.menuViewFrame = menuFrame
        
        guard let contentFrame = self.dataSource?.pageController(self, preferredFrameForContentView: self.scrollView) else { return  }
        self.contentViewFrame = contentFrame
        childViewFrames.removeAll()
        for i in 0..<childControllersCount {
            childViewFrames.append(CGRect(x: CGFloat(i) * contentFrame.size.width, y: 0, width: contentFrame.size.width, height: contentFrame.size.height))
        }
    }
    
    func lz_addScrollView() {
        let scrollView = LZPageScrollView();
        scrollView.scrollsToTop = false
        scrollView.isPagingEnabled = true
        scrollView.backgroundColor = UIColor.white
        scrollView.delegate = self
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = self.bounces;
        scrollView.isScrollEnabled = self.scrollEnable;
        if #available(iOS 11, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        }
        if let parentContentView = self.dataSource?.pageController?(self, preferredParentViewForContentView: scrollView) {
            parentContentView.insertSubview(scrollView, at: 0)
        }else {
            self.getHorizontalScrollViewSuperView().insertSubview(scrollView, at: 0)
        }
        self.scrollView = scrollView;
        
        if let nav = self.navigationController {
            if let gestureRecognizers = scrollView.gestureRecognizers, let interactivePopGesture = nav.interactivePopGestureRecognizer {
                for gesture in gestureRecognizers {
                    gesture.require(toFail: interactivePopGesture)
                }
            }
            
        }
    }
    
    func lz_addMenuView() {
        let menuView = LZMenuView()
        menuView.delegate = self
        menuView.dataSource = self
        menuView.style = self.menuViewStyle
        menuView.layoutMode = self.menuViewLayoutMode
        menuView.progressHeight = self.progressHeight
        if let menuViewContentMargin = self.menuViewContentMargin {
            menuView.contentMargin = menuViewContentMargin
        }
        if let progressViewBottomSpace = self.progressViewBottomSpace {
            menuView.progressViewBottomSpace = progressViewBottomSpace
        }
        if let progressViewIsNaughty = self.progressViewIsNaughty {
            menuView.progressViewIsNaughty = progressViewIsNaughty
        }
        menuView.progressWidths = self.progressViewWidths
        menuView.progressViewCornerRadius = self.progressViewCornerRadius
        menuView.showOnNavigationBar = self.showOnNavigationBar
        
        if let titleFontName = self.titleFontName {
            menuView.fontName = titleFontName
        }
        if let progressColor = self.progressColor {
            menuView.lineColor = progressColor
        }
        
        if (self.showOnNavigationBar && self.navigationController?.navigationBar != nil) {
            self.navigationItem.titleView = menuView;
        } else {
            if let parentView = self.dataSource?.pageController?(self, preferredParentViewForMenu: menuView) {
                parentView.addSubview(menuView)
            }else {
                self.getMenuSuperView().addSubview(menuView)
            }
        }
        
        self.menuView = menuView
    }
    
    
    func titleAtIndex(_ index: Int) -> String {
        
        if let title = self.dataSource?.pageController?(self, titleAtIndex: index) {
            return title
        }
        
        if let titles = self.titles {
            if titles.count > index {
                return titles[index]
            }
        }
        
        return ""
    }
    
    func lz_layoutChildViewControllers() {

        let currentPage = Int(self.scrollView!.contentOffset.x / contentViewFrame.size.width)

        let length = preloadPolicy.rawValue
        let left = currentPage - length - 1
        let right = currentPage + length + 1
        for i in 0..<childControllersCount {
            let vc = displayVC[i]
            if i < childViewFrames.count {
                let frame = childViewFrames[i]
                if vc == nil {
                    if self.lz_isInScreen(frame) {
                        self.lz_initializedControllerWithIndexIfNeeded(i)
                    }
                }else {
                    if (i <= left || i >= right) {
                        if !self.lz_isInScreen(frame) {
                            self.lz_removeViewController(vc!, atIndex: i)
                        }
                    }
                }
            }
        }
    }

    // 创建或从缓存中获取控制器并添加到视图上
    func lz_initializedControllerWithIndexIfNeeded(_ index: Int) {
        // 先从 cache 中取
        if let vc = self.memCache.object(forKey: NSNumber(value: index)) {
            // cache 中存在，添加到 scrollView 上，并放入display
            self.lz_addCachedViewController(vc, atIndex: index)
        }else {
            // cache 中也不存在，创建并添加到display
            self.lz_addViewControllerAtIndex(index)
        }
        self.lz_postAddToSuperViewNotificationWithIndex(index)
    }

    func lz_addCachedViewController(_ viewController: UIViewController, atIndex index: Int) {
        self.addChildViewController(viewController)
        viewController.view.frame = childViewFrames[index]
        viewController.didMove(toParentViewController: self)
        scrollView?.addSubview(viewController.view)
        self.willEnterController(viewController, atIndex: index)
        displayVC[index] = viewController
    }
    // 创建并添加子控制器
    func lz_addViewControllerAtIndex(_ index: Int) {
        initializedIndex = index
        if let viewController = self.initializeViewControllerAtIndex(index) {
            if let values = self.values, let keys = self.keys {
                if values.count == childControllersCount && keys.count == childControllersCount {
                    if index < values.count && index < keys.count {
                        viewController.setValue(values[index], forKey: keys[index])
                    }
                }
            }
            
            self.addChildViewController(viewController)
            if index < childViewFrames.count {
                viewController.view.frame = childViewFrames[index]
            }else {
                viewController.view.frame = self.view.frame
            }
            viewController.didMove(toParentViewController: self)
            scrollView?.addSubview(viewController.view)
            self.willEnterController(viewController, atIndex: index)
            displayVC[index] = viewController
            
            self.lz_backToPositionIfNeeded(controller: viewController, atIndex: index)
        }
    }

    // 移除控制器，且从display中移除
    func lz_removeViewController(_ viewController: UIViewController, atIndex index: Int) {
        self.lz_rememberPositionIfNeeded(controller: viewController, atIndex: index)
        viewController.view.removeFromSuperview()
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        displayVC.removeValue(forKey: index)
        
        // 放入缓存
        if cachePolicy == .disabled {
            return
        }
        if self.memCache.object(forKey: NSNumber(value: index)) == nil {
            self.willCachedController(viewController, atIndex: index)
            self.memCache.setObject(viewController, forKey: NSNumber(value: index))
        }
    }
    
    func lz_backToPositionIfNeeded(controller: UIViewController, atIndex index: Int) {
        
        if self.memCache.object(forKey: NSNumber(value: index)) != nil {
            return
        }
        
        if let scrollView = self.lz_isKindOfScrollViewController(controller) {
            
            if let pointValue = posRecords[index] {
                scrollView.setContentOffset(pointValue, animated: false)
            }
        }
    }
    
    func lz_rememberPositionIfNeeded(controller: UIViewController, atIndex index: Int) {
        
        if let scrollView = self.lz_isKindOfScrollViewController(controller) {
            
            let pos = scrollView.contentOffset
            
            self.posRecords[index] = pos
        }
    }

    func lz_isKindOfScrollViewController(_ controller: UIViewController) -> UIScrollView? {
        var scrollView: UIScrollView?
        if controller.view is UIScrollView {
            // Controller的view是scrollView的子类(UITableViewController/UIViewController替换view为scrollView)
            scrollView = (controller.view as! UIScrollView)
            
        }else {
            if controller.view.subviews.count>=1 {
                // Controller的view的subViews[0]存在且是scrollView的子类，并且frame等与view得frame(UICollectionViewController/UIViewController添加UIScrollView)
                if let view = controller.view.subviews.first as? UIScrollView {
                    scrollView = view
                }
            }
        }
        return scrollView
    }
    
    func lz_isInScreen(_ frame: CGRect) -> Bool {
        guard let scrollView = self.scrollView else { return false }
        let x = frame.origin.x
        let screeenWidth = scrollView.frame.size.width
        let contentOffsetX = scrollView.contentOffset.x
        if (frame.maxX > contentOffsetX) && (x - contentOffsetX < screeenWidth) {
            return true
        }
        return false
    }

    func lz_resetMenuView() {
        if let menuView = self.menuView {
            menuView.reload()
            if !menuView.isUserInteractionEnabled {
                menuView.isUserInteractionEnabled = true
            }
            if _selectIndex != 0 {
                menuView.selectItemAtIndex(_selectIndex)
            }
            self.getMenuSuperView().bringSubview(toFront: menuView)
        }else {
            self.lz_addMenuView()
        }
    }
    
    @objc func lz_growCachePolicyAfterMemoryWarning() {
        cachePolicy = .balanced
        self.perform(#selector(lz_growCachePolicyToHigh), with: nil, afterDelay: 2.0, inModes: [RunLoopMode.commonModes])
    }
    
    @objc func lz_growCachePolicyToHigh() {
        cachePolicy = .high
    }
    
    //MARK: -- public methods
    func reloadData() {
        self.lz_clearDatas()
        if childControllersCount <= 0 {
            return
        }
        //这里放在scrollview前面，保证刷新时childViewFrames有数据选择任意下标时不崩溃
        self.viewDidLayoutSubviews()
        self.lz_resetScrollView()
        self.memCache.removeAllObjects()
        self.lz_resetMenuView()
        self.didEnterController(currentViewController, atIndex: _selectIndex)
    }
    
    func updateTitle(_ title: String, atIndex index: Int) {
        self.menuView?.updateTitle(title, atIndex: index, andWidth: false)
    }
    
    func updateAttributeTitle(_ title: NSAttributedString, atIndex index: Int) {
        self.menuView?.updateAttributeTitle(title, atIndex: index, andWidth: false)
    }
    
    func updateTitle(_ title: String, andWidth width: CGFloat, atIndex index: Int) {
        if var itemsWidths = self.itemsWidths, index < itemsWidths.count {
            itemsWidths[index] = width
            self.itemsWidths = itemsWidths
        }else {
            var mutableWidths = [CGFloat]()
            for i in 0..<childControllersCount {
                let itemWidth = i==index ? width : menuItemWidth
                mutableWidths.append(itemWidth)
            }
            self.itemsWidths = mutableWidths
        }
        self.menuView?.updateTitle(title, atIndex: index, andWidth: true)
    }
    
    //子类重写
    public func getHorizontalScrollViewSuperView() -> UIView {
        return self.view//默认self.view
    }
    //子类重写
    public func getMenuSuperView() -> UIView {
        return self.view;
    }
    
    //MARK: - Adjust Frame
    func lz_adjustScrollViewFrame() {
        // While rotate at last page, set scroll frame will call `-scrollViewDidScroll:` delegate
        // It's not my expectation, so I use `_shouldNotScroll` to lock it.
        // Wait for a better solution.
        guard let scrollView = self.scrollView else { return  }
        shouldNotScroll = true
        let oldContentOffsetX = scrollView.contentOffset.x
        let contentWidth = scrollView.contentSize.width
        scrollView.frame = contentViewFrame
        scrollView.contentSize = CGSize(width: CGFloat(childControllersCount) * contentViewFrame.size.width, height: 0)
        let xContentOffset = contentWidth == 0 ? CGFloat(_selectIndex) * contentViewFrame.size.width : oldContentOffsetX / contentWidth * CGFloat(childControllersCount) * contentViewFrame.size.width
        scrollView.contentOffset = CGPoint(x: xContentOffset, y: 0)
        shouldNotScroll = false
    }
    
    func lz_adjustDisplayingViewControllersFrame() {
        for (index, vc) in displayVC {
            if index < childViewFrames.count {
                vc.view.frame = childViewFrames[index]
            }
        }
    }
    
    func lz_adjustMenuViewFrame() {
        guard let menuView = self.menuView else { return }
        let oriWidth = menuView.frame.size.width
        menuView.frame = menuViewFrame
        menuView.resetFrames()
        if oriWidth != menuView.frame.size.width {
            menuView.refreshContenOffset()
        }
    }
    
    func lz_calculateItemWithAtIndex(_ index: Int) -> CGFloat {
        let title = self.titleAtIndex(index)
        
        var titleFont: UIFont!
        
        if let titleFontName = self.titleFontName {
            titleFont = UIFont(name: titleFontName, size: titleSizeSelected)
        }else {
            titleFont = UIFont.boldSystemFont(ofSize: titleSizeSelected)
        }
        
        let ocTitle = title as NSString
        
        let itemWidth = ocTitle.boundingRect(with: .zero, options: .usesFontLeading, attributes: [.font : titleFont!], context: nil).size.width
        
        return CGFloat(ceilf(Float(itemWidth)))
    }
    
    func lz_delaySelectIndexIfNeeded() {
        //        if (_markedSelectIndex != kJWUndefinedIndex) {
        //            self.selectIndex = (int)_markedSelectIndex;
        //        }
    }
}

extension LZPageController: LZPageControllerDataSource, LZPageControllerDelegate {
    func pageController(_ pageController: LZPageController, preferredFrameForContentView contentView: LZPageScrollView?) -> CGRect {
        assert(false, "子类必须实现")
        return .zero
    }
    
    func pageController(_ pageController: LZPageController, preferredFrameForMenuView menuView: LZMenuView?) -> CGRect {
        assert(false, "子类必须实现")
        return .zero
    }
    
}

extension LZPageController: LZMenuViewDataSource, LZMenuViewDelegate {
    func menuView(_ menu: LZMenuView, didSelesctedIndex index: Int, currentIndex: Int) {
        if !hasInited {
            return
        }
        
        if currentIndex == index {
            self.delegate?.pageController?(self, didClickIndexAgainWithIndex: index)
            return
        }
        
        _selectIndex = index
        
        startDragging = false
        self.scrollView?.setContentOffset(CGPoint(x: contentViewFrame.size.width * CGFloat(index), y: 0), animated: pageAnimatable)
        
        if pageAnimatable {
            return
        }
        
        if let currentViewController = self.displayVC[currentIndex] {
            self.lz_removeViewController(currentViewController, atIndex: currentIndex)
        }
            
        self.lz_layoutChildViewControllers()
        self.didEnterController(self, atIndex: index)
        
//        self.setNeedsStatusBarAppearanceUpdate()//根据子控制器更新状态栏
    }
    func menuView(_ menu: LZMenuView, widthForItemAtIndex index: Int) -> CGFloat {
        if self.automaticallyCalculatesItemWidths {
            return self.lz_calculateItemWithAtIndex(index)
        }
        
        if let itemsWidths = itemsWidths, itemsWidths.count == childControllersCount {
            return itemsWidths[index]
        }
        
        return self.menuItemWidth;
    }
    func menuView(_ menu: LZMenuView, itemMarginAtIndex index: Int) -> CGFloat {
        if let itemsMargins = itemsMargins, itemsMargins.count == self.childControllersCount + 1 {
            return itemsMargins[index]
        }
        return self.itemMargin ?? 0
    }
    func menuView(_ menu: LZMenuView, titleSizeForState state: LZMenuItemState, atIndex index: Int) -> CGFloat {
        switch state {
            case .selected:
                return titleSizeSelected
            default:
                return titleSizeNormal
        }
    }
    func menuView(_ menu: LZMenuView, titleColorForState state: LZMenuItemState, atIndex index: Int) -> UIColor {
        switch state {
            case .selected:
                return titleColorSelected
            default:
                return titleColorNormal
        }
    }
    
    func numbersOfTitlesInMenuView(_ menu: LZMenuView) -> Int {
        return self.childControllersCount
    }
    func menuView(_ menu: LZMenuView, titleAtIndex index: Int) -> String {
        return self.titleAtIndex(index)
    }
}

extension LZPageController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        if shouldNotScroll || !hasInited {
            return
        }
        self.lz_layoutChildViewControllers()
        if startDragging {
            var contentOffsetX = scrollView.contentOffset.x
            if contentOffsetX < 0 {
                contentOffsetX = 0
            }
            if contentOffsetX > scrollView.contentSize.width - contentViewFrame.size.width {
                contentOffsetX = scrollView.contentSize.width - contentViewFrame.size.width
            }
            let rate = contentOffsetX / contentViewFrame.size.width
            self.menuView?.slideMenuAtProgress(rate)
        }
        // Fix scrollView.contentOffset.y -> (-20) unexpectedly.
        if (scrollView.contentOffset.y == 0) {return}
        var contentOffset = scrollView.contentOffset
        contentOffset.y = 0.0;
        scrollView.contentOffset = contentOffset;
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        startDragging = true
        self.menuView?.isUserInteractionEnabled = false
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        self.menuView?.isUserInteractionEnabled = true
        _selectIndex = Int(scrollView.contentOffset.x / contentViewFrame.size.width)
        currentViewController = displayVC[_selectIndex]
        self.didEnterController(currentViewController, atIndex: _selectIndex)
        self.menuView?.deselectedItemsIfNeeded()
        
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        currentViewController = displayVC[_selectIndex]
        self.didEnterController(currentViewController, atIndex: _selectIndex)
        self.menuView?.deselectedItemsIfNeeded()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        if !decelerate {
            self.menuView?.isUserInteractionEnabled = true
            let rate = targetX / contentViewFrame.size.width
            self.menuView?.slideMenuAtProgress(rate)
            self.menuView?.deselectedItemsIfNeeded()
        }
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if !(scrollView is LZPageScrollView) {
            return
        }
        targetX = targetContentOffset.pointee.x
    }


}
