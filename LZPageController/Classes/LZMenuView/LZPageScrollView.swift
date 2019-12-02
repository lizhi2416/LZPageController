//
//  LZPageScrollView.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/10.
//  Copyright © 2019 lizhi. All rights reserved.
//

import UIKit

class LZPageScrollView: UIScrollView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension LZPageScrollView {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if otherGestureRecognizer is UIPanGestureRecognizer {
            if let otherGesView = otherGestureRecognizer.view, NSStringFromClass(otherGesView.classForCoder) == "UITableViewWrapperView" {
                return true
            }
        }
        
        return false
    }
    
}
