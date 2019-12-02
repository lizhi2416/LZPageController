//
//  LZPageControllerDelegate.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/10.
//  Copyright © 2019 lizhi. All rights reserved.
//

import Foundation

@objc protocol LZPageControllerDelegate: class {
    /**
     *  If the child controller is heavy, put some work in this method. This method will only be called when the controller is initialized and stop scrolling. (That means if the controller is cached and hasn't released will never call this method.)
     *
     *  @param pageController The parent controller (JWPageController)
     *  @param viewController The viewController first show up when scroll stop.
     *  @param info           A dictionary that includes some infos, such as: `index` / `title`
     */
    @objc optional func pageController(_ pageController: LZPageController, lazyLoadViewController viewController: UIViewController, withInfo info: [String:Any])

    /**
     *  Called when a viewController will be cached. You can clear some data if it's not reusable.
     *
     *  @param pageController The parent controller (JWPageController)
     *  @param viewController The viewController will be cached.
     *  @param info           A dictionary that includes some infos, such as: `index` / `title`
     */
    @objc optional func pageController(_ pageController: LZPageController, willCachedViewController viewController: UIViewController, withInfo info: [String:Any])

    /**
     *  Called when a viewController will be appear to user's sight. Do some preparatory methods if needed.
     *
     *  @param pageController The parent controller (JWPageController)
     *  @param viewController The viewController will appear.
     *  @param info           A dictionary that includes some infos, such as: `index` / `title`
     */
    @objc optional func pageController(_ pageController: LZPageController, willEnterViewController viewController: UIViewController, withInfo info: [String:Any])

    /**
     *  Called when a viewController will fully displayed, that means, scrollView have stopped scrolling and the controller's view have entirely displayed.
     *
     *  @param pageController The parent controller (JWPageController)
     *  @param viewController The viewController entirely displayed.
     *  @param info           A dictionary that includes some infos, such as: `index` / `title`
     */
    @objc optional func pageController(_ pageController: LZPageController, didEnterViewController viewController: UIViewController, withInfo info: [String: Any])

    /*
     再次点击menuview同一按钮回调，主要用于是否刷新列表
    */
    @objc optional func pageController(_ pageController: LZPageController, didClickIndexAgainWithIndex index: Int)
}
