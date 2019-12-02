//
//  LZPageController+cache.swift
//  Cartoon-Swift
//
//  Created by 蒋理智 on 2019/10/10.
//  Copyright © 2019 lizhi. All rights reserved.
//

import UIKit

/*
 *  LZPageController 的缓存设置，默认缓存为无限制，当收到 memoryWarning 时，会自动切换到低缓存模式 (LowMemory)，并在一段时间后切换到 High .
    收到多次警告后，会停留在到 LowMemory 不再增长
 *
 *  The Default cache policy is No Limit, when recieved memory warning, page controller will switch mode to 'LowMemory'
    and continue to grow back after a while.
    If recieved too much times, the cache policy will stay at 'LowMemory' and don't grow back any more.
 */
enum LZPageControllerCachePolicy: Int {
    case disabled = -1 // Disable Cache
    case noLimit  = 0// No limit
    case lowMemory = 1// Low Memory but may block when scroll
    case balanced  = 3// Balanced ↑ and ↓
    case high = 5 // High
}

extension LZPageController {
    func cache_setup() {
                
        NotificationCenter.default.addObserver(self, selector: #selector(willResignActive), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
    }
    
    @objc func willResignActive() {
        for i in 0..<self.childControllersCount {
            let obj = self.memCache.object(forKey: NSNumber(value: i))
            if let obj = obj {
                self.backgroundCache[i] = obj
            }
        }
    }
    
    @objc func willEnterForeground() {
        for (index, vc) in self.backgroundCache {
            if self.memCache.object(forKey: NSNumber(value: index)) == nil {
                self.memCache.setObject(vc, forKey: NSNumber(value: index))
            }
        }
        self.backgroundCache.removeAll()
    }
}
