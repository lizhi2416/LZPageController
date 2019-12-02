//
//  LZPageControllerDataSource.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/10.
//  Copyright © 2019 lizhi. All rights reserved.
//

import Foundation

@objc protocol LZPageControllerDataSource: AnyObject {
    
    /**
     Implement this datasource method, in order to customize your own contentView's frame

     @param pageController The container controller
     @param contentView The contentView, each is the superview of the child controllers
     @return The frame of the contentView
     */
    func pageController(_ pageController: LZPageController, preferredFrameForContentView contentView: LZPageScrollView?) -> CGRect

    /**
     Implement this datasource method, in order to customize your own menuView's frame
     
     @param pageController The container controller
     @param menuView The menuView
     @return The frame of the menuView
     */
    func pageController(_ pageController: LZPageController, preferredFrameForMenuView menuView: LZMenuView?) -> CGRect
    
    /**
     *  To inform how many child controllers will in `JWPageController`.
     *
     *  @param pageController The parent controller.
     *
     *  @return The value of child controllers's count.
     */
    @objc optional func numbersOfChildControllersInPageController(_ pageController: LZPageController) -> Int

    /**
     *  Return a controller that you wanna to display at index. You can set properties easily if you implement this methods.
     *
     *  @param pageController The parent controller.
     *  @param index          The index of child controller.
     *
     *  @return The instance of a `UIViewController`.
     */
    @objc optional func pageController(_ pageController: LZPageController, viewControllerAtIndex index: Int) -> UIViewController
    /**
     *  Each title you wanna show in the `JWMenuView`
     *
     *  @param pageController The parent controller.
     *  @param index          The index of title.
     *
     *  @return A `NSString` value to show at the top of `JWPageController`.
     */
    @objc optional func pageController(_ pageController: LZPageController, titleAtIndex index: Int) -> String
    
    @objc optional func pageController(_ pageController: LZPageController, preferredParentViewForMenu menuView: LZMenuView?) -> UIView?
    
    @objc optional func pageController(_ pageController: LZPageController, preferredParentViewForContentView contentView: LZPageScrollView?) -> UIView?
}

